//
//  MockStorages.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import Foundation
import ContractusAPI

final class MockAccountStorage: AccountStorage {

    func addAccount(account: CommonAccount) { }

    func removeAccount(by publicKey: String) { }

    func getCurrentAccount() -> CommonAccount? {
        Mock.account
    }

    func setCurrentAccount(account: CommonAccount) {}

    func clearCurrentAccount() {}

    func getAccounts() -> [CommonAccount] {
        [Mock.account, Mock.account]
    }

    func updateAllAccounts(accounts: [CommonAccount]) {}
}

final class SharedSecretStorageMock: SharedSecretStorage {

    func getSharedSecret(for dealId: String) -> Data? {
        return nil
    }

    func saveSharedSecret(for dealId: String, sharedSecret: Data) throws {}

    func deleteSharedSecret(for dealId: String) throws {}

}

final class BackupStorageMock: BackupStorage {

    func removePrivateKey(_ value: String,  blockchain: Blockchain) throws {}

    func existInBackup(privateKey: String,  blockchain: Blockchain) -> Bool {
        true
    }

    func savePrivateKey(_ value: BackupKeyItem) throws {}

    func getBackupKeys() -> [BackupKeyItem] {
        [.init(publicKey: "123", privateKey: "123", blockchain: .solana)]
    }


}
