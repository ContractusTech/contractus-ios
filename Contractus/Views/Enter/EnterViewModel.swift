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
         saveAccount
}

struct EnterState {
    var account: CommonAccount?
    var privateKeyIsCopied: Bool = false
    var isBackupedPrivateKey: Bool = false
    var blockchain: Blockchain?
}

final class EnterViewModel: ViewModel {

    @Published var state: EnterState

    private let accountService: AccountService
    private var apiClient: ContractusAPI.APIClient?

    init(initialState: EnterState, accountService: AccountService) {
        self.state = initialState
        self.accountService = accountService
    }

    func trigger(_ input: EnterInput, after: AfterTrigger? = nil) {
        switch input {
        case .importPrivateKey(let privateKey):
            guard let blockchain = state.blockchain else { return }
            guard let account = try? accountService.restore(by: privateKey, blockchain: blockchain) else {
                return
            }
            self.state.account = account
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
        case .copyPrivateKey:
            guard let privateKey = state.account?.privateKey else { return }
            UIPasteboard.general.string = privateKey.toHexString()
            self.state.privateKeyIsCopied = true
        case .copyForBackup:
            guard let privateKey = state.account?.privateKey else { return }
            UIPasteboard.general.string = privateKey.toHexString()
            self.state.isBackupedPrivateKey = true
        case .saveAccount:
            guard let account = state.account else { return }
            accountService.save(account)
        case .setBlockchain(let blockchain):
            self.state.blockchain = blockchain
        }
    }
}
