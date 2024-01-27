import Foundation
import ContractusAPI

final class UtilsStorage {

    private enum Keys: String {
        case tokenSettings

        func value(_ account: CommonAccount) -> String {
            return "\(self.rawValue)-\(AppConfig.serverType.networkTitle)-\(account.publicKey)-\(account.blockchain.rawValue)"
        }
    }

    static let shared = UtilsStorage()

    private var storage = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func getTokenSettings(account: CommonAccount) -> [ContractusAPI.Token]? {
        if
            let data = storage.data(forKey: Keys.tokenSettings.value(account)),
            let settings = try? decoder.decode([StoreToken].self, from: data) {

            return settings.map { $0.asToken }
        }

        return nil
    }

    func saveTokenSettings(tokens: [ContractusAPI.Token], account: CommonAccount) {
        guard let data = try? encoder.encode(tokens.map { $0.asInternalToken }) else { return }
        storage.set(data, forKey: Keys.tokenSettings.value(account))
    }

    func debugClearSettings(account: CommonAccount) {
        storage.removeObject(forKey: Keys.tokenSettings.value(account))
    }
}

fileprivate struct StoreToken: Codable {
    let code: String
    let name: String?
    let address: String?
    let native: Bool
    let decimals: Int
    let serviced: Bool
    let logoURL: URL?
    let holderMode: Bool
}

fileprivate extension StoreToken {
    var asToken: ContractusAPI.Token {
        .init(code: self.code, name: self.name, address: self.address, native: self.native, decimals: self.decimals, serviced: self.serviced, logoURL: self.logoURL, holderMode: self.holderMode)
    }
}

fileprivate extension ContractusAPI.Token {
    var asInternalToken: StoreToken {
        .init(code: self.code, name: self.name, address: self.address, native: self.native, decimals: self.decimals, serviced: self.serviced, logoURL: self.logoURL, holderMode: self.holderMode)
    }
}

// TODO: - Remove in next releases

final class OldUtilsStorage {

    private enum Keys: String {
        case tokenSettings

        var value: String {
            return "\(self.rawValue)_\(AppConfig.serverType.networkTitle)"
        }
    }

    static let shared = OldUtilsStorage()

    private var storage = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func getTokenSettings() -> [ContractusAPI.Token]? {
        if
            let data = storage.data(forKey: Keys.tokenSettings.value),
            let settings = try? decoder.decode([StoreToken].self, from: data) {

            return settings.map { $0.asToken }
        }

        return nil
    }

    func saveTokenSettings(tokens: [ContractusAPI.Token]) {
        guard let data = try? encoder.encode(tokens.map { $0.asInternalToken }) else { return }
        storage.set(data, forKey: Keys.tokenSettings.value)
    }

    func clear() {
        storage.removeObject(forKey: Keys.tokenSettings.value)
    }
}
