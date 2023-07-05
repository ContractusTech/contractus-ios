import Foundation
import KeychainAccess

protocol AuthStorage {
    func saveMessage(_ message: String) throws
    func getMessage() -> String?
    func clear()
}

final class KeychainAuthStorage: AuthStorage {

    enum Keys: String {
        static let serviceKey = "app.tech.Contractus.AuthMessage"
        case authMessage
        case deviceId
    }

    private let keychain = Keychain(service: Keys.serviceKey).accessibility(.whenUnlocked)

    func saveMessage(_ message: String) throws {
        try keychain.set(message, key: Keys.authMessage.rawValue)
    }

    func getMessage() -> String? {
        try? keychain.get(Keys.authMessage.rawValue)
    }

    func clear() {
        try? keychain.remove(Keys.authMessage.rawValue)
    }
}
