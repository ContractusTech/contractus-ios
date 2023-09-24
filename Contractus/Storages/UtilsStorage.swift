import Foundation
import ContractusAPI

final class UtilsStorage {

    private enum Keys: String {
        case tokenSettings
    }

    static let shared = UtilsStorage()

    private var storage = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func getTokenSettings() -> [ContractusAPI.Token]? {
        if
            let data = storage.data(forKey: Keys.tokenSettings.rawValue),
            let settings = try? decoder.decode([ContractusAPI.Token].self, from: data) {

            return settings
        }

        return nil
    }

    func saveTokenSettings(tokens: [ContractusAPI.Token]) {
        guard let data = try? encoder.encode(tokens) else { return }
        storage.set(data, forKey: Keys.tokenSettings.rawValue)
        storage.synchronize()
    }
}
