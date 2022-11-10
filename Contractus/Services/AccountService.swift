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
            return try Account(secretKey: keyPair.privateKey).commonAccount
        }
    }

    func restore(by privateKey: String, blockchain: Blockchain) throws -> CommonAccount {
        switch blockchain {
        case .solana:
            let privateKeyUInt8 = Base58.decode(privateKey)
            return try Account(secretKey: Data(privateKeyUInt8)).commonAccount
        }
    }

    func save(_ account: CommonAccount) {
        storage.setCurrentAccount(account: account)
    }

    func getCurrentAccount() -> CommonAccount? {
        return storage.getCurrentAccount()
    }

    // MARK: - Private Methods

    private func solanaGenerateKeyPair() throws -> (publicKey: String, privateKey: Data) {
        let keyPair = try NaclSign.KeyPair.keyPair()
        let publicKeyString = Base58.encode(keyPair.publicKey.bytes)
        return (publicKey: publicKeyString, privateKey: keyPair.secretKey)
    }
}
