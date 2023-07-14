import Foundation
import KeychainAccess

protocol AuthStorage {
    func saveMessageForSign(_ message: String, date: Date) throws
    func getMessageForSign() -> (String, Date)?
    func clear()
}

final class KeychainAuthStorage: AuthStorage {

    enum Keys: String {
        static let serviceKey = "\(AppConfig.bundleId).AuthMessage"
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

    func getMessageForSign() -> (String, Date)? {
        guard let message = try? keychain.get(Keys.authMessage.rawValue), let date = expiredDate(), date > Date() else {
            return nil
        }

        return (message, date)
    }

    func clear() {
        try? keychain.remove(Keys.authMessage.rawValue)
    }

    private func expiredDate() -> Date? {
        guard let dateString = try? keychain.get(Keys.expired.rawValue), let date = formatter.date(from: dateString) else {
            return nil
        }
        return date
    }
}
