import Foundation
import KeychainAccess

protocol AuthStorage {
    func saveMessageForSign(_ message: String, date: Date) throws
    func getMessageForSign() -> String?
    func clear()
}

final class KeychainAuthStorage: AuthStorage {

    enum Keys: String {
        static let serviceKey = "app.tech.Contractus.AuthMessage"
        case authMessage
        case expired
    }

    private let keychain = Keychain(service: Keys.serviceKey).accessibility(.whenUnlocked)
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    func saveMessageForSign(_ message: String, date: Date) throws {
        try keychain.set(message, key: Keys.authMessage.rawValue)
        debugPrint(formatter.string(from: date))
        try keychain.set(formatter.string(from: date), key: Keys.expired.rawValue)
    }

    func getMessageForSign() -> String? {
        if isExpired() {
            return nil
        }
        return try? keychain.get(Keys.authMessage.rawValue)
    }

    func clear() {
        try? keychain.remove(Keys.authMessage.rawValue)
    }

    private func isExpired() -> Bool {
        guard let dateString = try? keychain.get(Keys.expired.rawValue), let date = formatter.date(from: dateString) else {
            return false
        }
        return date < Date()
    }

}
