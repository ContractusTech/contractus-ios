//
//  BackupStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.04.2023.
//

import Foundation
import KeychainAccess
import ContractusAPI

struct BackupKeyItem: Decodable, Encodable, Hashable {
    let publicKey: String
    let privateKey: String
    let blockchain: Blockchain
}

protocol BackupStorage {
    func savePrivateKey(_ value: BackupKeyItem) throws
    func getBackupKeys() -> [BackupKeyItem]
    func removePrivateKey(_ value: String, blockchain: Blockchain) throws
    func existInBackup(privateKey: String, blockchain: Blockchain) -> Bool
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

    func savePrivateKey(_ value: BackupKeyItem) throws {
        var keys = getKeyList()
        keys.append(value)
        let uniqueKeys = keys.removingDuplicates()
        let data = try encoder.encode(uniqueKeys)
        try keychain.set(data, key: Keys.privateKeys.rawValue)
    }

    func getBackupKeys() -> [BackupKeyItem] {
        getKeyList()
    }

    func removePrivateKey(_ value: String, blockchain: Blockchain) throws {
        let keys = getKeyList().filter { $0.privateKey != value && $0.blockchain == blockchain }

        let data = try encoder.encode(keys)
        try keychain.set(data, key: Keys.privateKeys.rawValue)
    }

    func existInBackup(privateKey: String, blockchain: Blockchain) -> Bool {
        getKeyList().contains {$0.privateKey == privateKey && $0.blockchain == blockchain }
    }

    private func getKeyList() -> [BackupKeyItem] {
        let keys = (try? keychain.get(Keys.privateKeys.rawValue)) ?? "[]"
        guard let data = keys.data(using: .utf8), let keyList = try? decoder.decode([BackupKeyItem].self, from: data) else {
            return []
        }
        return keyList
    }
}
