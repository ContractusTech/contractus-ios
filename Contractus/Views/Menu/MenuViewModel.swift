//
//  MenuViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.11.2022.
//

import Foundation

enum MenuInput {
    case changeAccount(CommonAccount)
    case saveAccounts([CommonAccount])
}

struct MenuState {
    var accounts: [CommonAccount]
    var currentAccount: CommonAccount?
}

final class MenuViewModel: ViewModel {

    private let accountStorage: AccountStorage

    @Published private(set) var state: MenuState

    init(accountStorage: AccountStorage) {

        self.accountStorage = accountStorage

        self.state = .init(accounts: accountStorage.getListAccounts(), currentAccount: accountStorage.getCurrentAccount())

    }

    func trigger(_ input: MenuInput, after: AfterTrigger? = nil) {
        switch input {
        case .changeAccount(let commonAccount):
            accountStorage.setCurrentAccount(account: commonAccount)
        case .saveAccounts(let accounts):
            if accounts.isEmpty {
                accountStorage.clearCurrentAccount()
            }
            accountStorage.updateAccounts(accounts: accounts)
        }

    }
}
