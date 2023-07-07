import Foundation
import DeviceCheck
import KeychainAccess

class IdentifierService {

    enum Keys: String {
        static let serviceKey = "app.tech.Contractus.Identifier"
        case identifier
    }

    private let keychain = Keychain(service: Keys.serviceKey).synchronizable(true)
    private let authStorage: AuthStorage

    private(set) var deviceToken: String?
    private(set) var identifier: String!
    private(set) var message: String!
    private(set) var isSync: Bool = false

    init(authStorage: AuthStorage) {
        self.authStorage = authStorage
    }


    func sync() async {
        self.deviceToken = await getDeviceToken()
        self.identifier = getIdentifier()
        self.isSync = true
    }

    private func getDeviceToken() async -> String? {
        let device = DCDevice.current
        if device.isSupported {
            do {
                let token = try await device.generateToken()
                return token.base64EncodedString()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        #if DEBUG
        return "simulator-\(UUID().uuidString)"
        #endif
        return nil
    }

    private func getIdentifier() -> String {
        if let id = try? keychain.get(Keys.identifier.rawValue) {
            return id
        }

        let id = UUID().uuidString
        try? keychain.set(id, key: Keys.identifier.rawValue)
        return id
    }
}
