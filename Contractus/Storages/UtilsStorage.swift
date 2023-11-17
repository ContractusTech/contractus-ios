import Foundation
import ContractusAPI

final class UtilsStorage {

    private enum Keys: String {
        case tokenSettings

        func value(_ blockchain: Blockchain) -> String {
            return "\(self.rawValue)-\(AppConfig.serverType.networkTitle)-\(blockchain.rawValue)"
        }
    }

    static let shared = UtilsStorage()

    private var storage = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func getTokenSettings(blockchain: Blockchain) -> [ContractusAPI.Token]? {
        if
            let data = storage.data(forKey: Keys.tokenSettings.value(blockchain)),
            let settings = try? decoder.decode([StoreToken].self, from: data) {

            return settings.map { $0.asToken }
        }

        return nil
    }

    func saveTokenSettings(tokens: [ContractusAPI.Token], blockchain: Blockchain) {
        guard let data = try? encoder.encode(tokens.map { $0.asInternalToken }) else { return }
        storage.set(data, forKey: Keys.tokenSettings.value(blockchain))
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
