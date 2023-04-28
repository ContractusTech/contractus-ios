//
//  EnterViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.07.2022.
//

import Foundation
import SolanaSwift
import ContractusAPI
import UIKit

enum EnterInput {
    case importPrivateKey(String),
         setBlockchain(Blockchain),
         createIfNeeded,
         copyPrivateKey,
         copyForBackup,
         saveAccount(backupToiCloud: Bool),
         hideError
}

struct EnterState {

    enum ErrorState: Equatable {
        case error(String)
    }

    var errorState: ErrorState?
    var account: CommonAccount?
    var privateKeyIsCopied: Bool = false
    var isBackupedPrivateKey: Bool = false
    var blockchain: Blockchain?
    var isValidImportedPrivateKey: Bool = false
    var backupKeys: [BackupKeyItem] = []

    var hasBackupKeys: Bool {
        backupKeys.count > 0
    }
}

final class EnterViewModel: ViewModel {

    @Published var state: EnterState

    private let accountService: AccountService
    private let backupStorage: BackupStorage
    private var apiClient: ContractusAPI.APIClient?

    init(initialState: EnterState, accountService: AccountService, backupStorage: BackupStorage) {
        var state = initialState
        self.accountService = accountService
        self.backupStorage = backupStorage
        state.backupKeys = backupStorage.getBackupKeys()
        self.state = state
    }

    func trigger(_ input: EnterInput, after: AfterTrigger? = nil) {
        switch input {
        case .hideError:
            state.errorState = nil
        case .importPrivateKey(let privateKey):
            guard let blockchain = state.blockchain else { return }
            if accountService.existAccount(privateKey) {
                state.errorState = .error("This account already added.")
                return
            }
            guard let account = try? accountService.restore(by: privateKey, blockchain: blockchain) else {
                self.state.isValidImportedPrivateKey = false
                self.state.account = nil
                return
            }
            self.state.account = account
            self.state.isValidImportedPrivateKey = true
        case .createIfNeeded:
            guard let blockchain = state.blockchain else { return }
            guard self.state.account == nil, let account = try? accountService.create(blockchain: blockchain) else {
                return
            }
            self.state.account = account
//        case .reqeustAccountInfo:
//            guard let account = state.account, let header = try? AuthorizationHeaderBuilder.build(for: .solana, with: (publicKey: account.publicKey.base58EncodedString, privateKey: account.secretKey)) else { return }
//
//            apiClient = ContractusAPI.APIClient(server: AppConfig.serverType, authorizationHeader: header)
//            accountAPIService = ContractusAPI.AccountService(client: apiClient!)
//
//            accountAPIService?.getAccount { result in
//                switch result {
//                case .success(let account):
//                    debugPrint(account)
//                case .failure(let error):
//                    debugPrint(error)
//                }
//
//            }
        case .copyPrivateKey, .copyForBackup:
            UIPasteboard.general.string = state.account?.privateKey.toBase58()
            /// Maybe for logs will be useful
            break
        case .saveAccount(let allowBackup):
            guard let account = state.account else { return }

                do {
                    if allowBackup {

                        try backupStorage.savePrivateKey(.init(publicKey: account.publicKey, privateKey: account.privateKey.toBase58(), blockchain: account.blockchain))
                    }
                    accountService.save(account)
                }catch {
                    state.errorState = .error(error.readableDescription)
                }

        case .setBlockchain(let blockchain):
            self.state.blockchain = blockchain
        }
    }
}
