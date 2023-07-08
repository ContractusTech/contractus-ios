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

    func getAccounts() -> [CommonAccount]
    func updateAllAccounts(accounts: [CommonAccount])
    func addAccount(account: CommonAccount)
    func removeAccount(by publicKey: String)
}

final class KeychainAccountStorage: AccountStorage {

    enum Keys: String {
        static let serviceKey = "\(Bundle.main.bundleIdentifier!).Account"
        case currentAccountKey
        case accountList
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let keychain = Keychain(service: Keys.serviceKey).accessibility(.whenUnlocked)

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

    func getAccounts() -> [CommonAccount] {
        if
            let data = try? keychain.getData(Keys.accountList.rawValue),
            let accounts = try? decoder.decode([CommonAccount].self, from: data)
        {
            return accounts
        }
        return []
    }

    func updateAllAccounts(accounts: [CommonAccount]) {
        guard let json = try? encoder.encode(accounts.removingDuplicates()) else { return }
        try? keychain.set(json, key: Keys.accountList.rawValue)
    }

    func addAccount(account: CommonAccount) {
        saveToListAccount(account: account)
    }

    func removeAccount(by publicKey: String) {
        let accounts = getAccounts().filter { $0.publicKey != publicKey }
        guard let json = try? encoder.encode(accounts) else { return }
        try? keychain.set(json, key: Keys.accountList.rawValue)
    }

    private func saveToListAccount(account: CommonAccount) {
        var accounts = getAccounts()
        accounts.append(account)
        accounts = accounts.removingDuplicates()
        guard let json = try? encoder.encode(accounts) else { return }
        try? keychain.set(json, key: Keys.accountList.rawValue)
    }

}
