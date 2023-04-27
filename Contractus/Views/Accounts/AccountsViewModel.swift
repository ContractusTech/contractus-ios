//
//  AccountsViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.04.2023.
//

import Foundation

final class AccountsViewModel: ViewModel {

    enum Input {
        case reload
        case changeAccount(CommonAccount)
        case deleteAccount(CommonAccount, fromBackup: Bool)
        case backup(CommonAccount, allow: Bool)
    }

    struct AccountItem: Hashable {
        let account: CommonAccount
        let existInBackup: Bool
    }

    struct State {
        var accounts: [AccountItem]
        var currentAccount: CommonAccount?
    }

    private let accountStorage: AccountStorage
    private let backupStorage: BackupStorage

    @Published private(set) var state: State

    init(accountStorage: AccountStorage, backupStorage: BackupStorage) {
        self.accountStorage = accountStorage
        self.backupStorage = backupStorage
        self.state = .init(
            accounts: accountStorage.getAccounts().map {
                .init(account: $0, existInBackup: backupStorage.existInBackup(privateKey: $0.privateKey.toBase58()))
            },
            currentAccount: accountStorage.getCurrentAccount())
    }

    func trigger(_ input: Input, after: AfterTrigger? = nil) {
        switch input {
        case .reload:
            self.state.accounts = accountStorage.getAccounts().map {.init(account: $0, existInBackup: backupStorage.existInBackup(privateKey: $0.privateKey.toBase58()))}
        case .changeAccount(let commonAccount):
            accountStorage.setCurrentAccount(account: commonAccount)
            state.currentAccount = commonAccount
        case .backup(let account, let allow):
            if allow {
                try? backupStorage.savePrivateKey(account.privateKey.toBase58())
            } else {
                try? backupStorage.removePrivateKey(account.privateKey.toBase58())
            }
            self.state.accounts = accountStorage.getAccounts().map {.init(account: $0, existInBackup: backupStorage.existInBackup(privateKey: $0.privateKey.toBase58()))}

        case .deleteAccount(let account, let fromBackup):
            if fromBackup {
                try? backupStorage.removePrivateKey(account.privateKey.toBase58())
            }
            accountStorage.removeAccount(by: account.publicKey)
            state.accounts = state.accounts.filter {$0.account.publicKey != account.publicKey }
            if state.accounts.isEmpty {
                appState.trigger(.logout)
            } else {
                if account.publicKey == state.currentAccount?.publicKey, let current = state.accounts.first?.account {
                    accountStorage.setCurrentAccount(account: current)
                    state.currentAccount = current
                }
            }


//            accountStorage.updateAccounts(accounts: <#T##[CommonAccount]#>)
//            if accounts.isEmpty {
//                accountStorage.clearCurrentAccount()
//            }
//            accountStorage.updateAccounts(accounts: accounts)
        }

    }
}

