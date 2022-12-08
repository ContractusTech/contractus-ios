//
//  KeychainService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import KeychainAccess
import Foundation
import enum ContractusAPI.Blockchain

protocol AccountStorage {
    func getCurrentAccount() -> CommonAccount?
    func setCurrentAccount(account: CommonAccount)
    func clearCurrentAccount()
    func getListAccounts() -> [CommonAccount]
    func updateAccounts(accounts: [CommonAccount])
}

final class KeychainAccountStorage: AccountStorage {

    enum Keys: String {
        static let serviceKey = "app.me.Contractus.Account"
        case currentAccountKey
        case accountList

    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let keychain = Keychain(service: Keys.serviceKey)

    func getCurrentAccount() -> CommonAccount? {
        if
            let data = try? keychain.getData(Keys.currentAccountKey.rawValue),
            let account = try? decoder.decode(CommonAccount.self, from: data)
        {
            return account
        }
        return nil
    }

    func setCurrentAccount(account: CommonAccount) {
        guard let json = try? encoder.encode(account) else { return }
        try? keychain.set(json, key: Keys.currentAccountKey.rawValue)
        saveToListAccount(account: account)
    }

    func clearCurrentAccount() {
        try? keychain.remove(Keys.currentAccountKey.rawValue)
    }

    func getListAccounts() -> [CommonAccount] {
        if
            let data = try? keychain.getData(Keys.accountList.rawValue),
            let accounts = try? decoder.decode([CommonAccount].self, from: data)
        {
            return accounts
        }
        return []
    }

    private func saveToListAccount(account: CommonAccount) {
        var accounts = getListAccounts()
        accounts.append(account)
        accounts = Array(Set(accounts))
        guard let json = try? encoder.encode(accounts) else { return }
        try? keychain.set(json, key: Keys.accountList.rawValue)
    }

    func updateAccounts(accounts: [CommonAccount]) {
        guard let json = try? encoder.encode(Array(Set(accounts))) else { return }
        try? keychain.set(json, key: Keys.accountList.rawValue)
    }


}
