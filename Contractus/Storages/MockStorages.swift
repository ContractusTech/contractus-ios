//
//  MockStorages.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import Foundation


class MockAccountStorage: AccountStorage {
    func getCurrentAccount() -> CommonAccount? {
        Mock.account
    }

    func setCurrentAccount(account: CommonAccount) { }

    func clearCurrentAccount() { }

    func getListAccounts() -> [CommonAccount] {
        []
    }
}
