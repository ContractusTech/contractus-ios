//
//  BackupStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.04.2023.
//

import Foundation
import KeychainAccess

protocol BackupStorage {
    func savePrivateKey(_ value: String) throws
    func getBackupKeys() -> [String]
    func removePrivateKey(_ value: String) throws
    func existInBackup(privateKey: String) -> Bool
}

final class iCloudBackupStorage: BackupStorage {

    enum Keys: String {
        static let serviceKey = "app.tech.Contractus.Backup"
        case privateKeys
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let keychain = Keychain(service: Keys.serviceKey)
        .accessibility(.whenUnlocked)
        .synchronizable(true)

    func savePrivateKey(_ value: String) throws {
        var keys = getKeyList()
        keys.append(value)
        let uniqueKeys = keys.removingDuplicates()
        let data = try encoder.encode(uniqueKeys)
        try keychain.set(data, key: Keys.privateKeys.rawValue)
    }

    func getBackupKeys() -> [String] {
        getKeyList()
    }

    func removePrivateKey(_ value: String) throws {
        let keys = getKeyList().filter { $0 != value }

        let data = try encoder.encode(keys)
        try keychain.set(data, key: Keys.privateKeys.rawValue)
    }

    func existInBackup(privateKey: String) -> Bool {
        getKeyList().contains {$0 == privateKey }
    }

    private func getKeyList() -> [String] {
        let keys = (try? keychain.get(Keys.privateKeys.rawValue)) ?? "[]"
        guard let data = keys.data(using: .utf8), let keyList = try? decoder.decode([String].self, from: data) else {
            return []
        }
        return keyList
    }
}
