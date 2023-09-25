//
//  AccountService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import Foundation
import TweetNacl
import SolanaSwift
import enum ContractusAPI.Blockchain

protocol AccountService {
    func create(blockchain: Blockchain) throws -> CommonAccount
    func restore(by privateKey: String, blockchain: Blockchain) throws -> CommonAccount
    func save(_ account: CommonAccount)
    func getCurrentAccount() -> CommonAccount?
    func existAccount(_ pk: String) -> Bool
}

final class AccountServiceImpl: AccountService {

    private let storage: AccountStorage

    init(storage: AccountStorage){
        self.storage = storage
    }

    func create(blockchain: Blockchain) throws -> CommonAccount {
        switch blockchain {
        case .solana:
            let keyPair = try solanaGenerateKeyPair()
            return try KeyPair(secretKey: keyPair.privateKey).commonAccount
        }
    }

    func restore(by privateKey: String, blockchain: Blockchain) throws -> CommonAccount {
        switch blockchain {
        case .solana:
            let privateKeyUInt8 = Base58.decode(privateKey)
            return try KeyPair(secretKey: Data(privateKeyUInt8)).commonAccount
        }
    }

    func save(_ account: CommonAccount) {
        storage.setCurrentAccount(account: account)
        MessagingService.shared.subscribe(to: account.publicKey)
    }

    func getCurrentAccount() -> CommonAccount? {
        return storage.getCurrentAccount()
    }

    func existAccount(_ pk: String) -> Bool {
        return storage.getAccounts().contains {$0.privateKey.toBase58() == pk }
    }

    // MARK: - Private Methods

    private func solanaGenerateKeyPair() throws -> (publicKey: String, privateKey: Data) {
        let keyPair = try NaclSign.KeyPair.keyPair()
        let publicKeyString = Base58.encode(keyPair.publicKey.bytes)
        return (publicKey: publicKeyString, privateKey: keyPair.secretKey)
    }
}
