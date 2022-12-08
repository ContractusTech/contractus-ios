//
//  MockStorages.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import Foundation


final class MockAccountStorage: AccountStorage {

    func getCurrentAccount() -> CommonAccount? {
        Mock.account
    }

    func setCurrentAccount(account: CommonAccount) { }

    func clearCurrentAccount() { }

    func getListAccounts() -> [CommonAccount] {
        [Mock.account, Mock.account]
    }

    func updateAccounts(accounts: [CommonAccount]) { }
}


final class SharedSecretStorageMock: SharedSecretStorage {
    func getSharedSecret(for dealId: String) -> Data? {
        return nil
    }

    func saveSharedSecret(for dealId: String, sharedSecret: Data) throws {

    }

    func deleteSharedSecret(for dealId: String) throws {

    }

}
