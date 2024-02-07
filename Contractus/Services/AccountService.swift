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
import Web3Core

enum AccountServiceError: Error {
    case errorGenerateAccount
    case invalidPublicKey
}

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
            return try KeyPair(secretKey: keyPair.privateKey).commonAccount
        case .bsc:
            let keyPair = try evmGenerateKeyPair()
            return .init(
                publicKeyData: keyPair.publicKey,
                publicKey: Utilities.publicToAddressString(keyPair.publicKey) ?? "",
                privateKey: keyPair.privateKey,
                blockchain: .bsc)
        }
    }

    func restore(by privateKey: String, blockchain: Blockchain) throws -> CommonAccount {
        switch blockchain {
        case .solana:
            if privateKey.first == "[", let data = privateKey.data(using: .utf8) {
                let privateKeyUInt8 = try  JSONDecoder().decode(Array<UInt8>.self, from: data)
                return try KeyPair(secretKey: Data(privateKeyUInt8)).commonAccount
            } else {
                let privateKeyUInt8 = Base58.decode(privateKey)
                return try KeyPair(secretKey: Data(privateKeyUInt8)).commonAccount
            }
        case .bsc:
            let privateKey = Data(hex: privateKey)
            guard let publicKey = Utilities.privateToPublic(privateKey) else { throw AccountServiceError.invalidPublicKey }

            return .init(
                publicKeyData: publicKey,
                publicKey: Utilities.publicToAddressString(publicKey) ?? "",
                privateKey: privateKey,
                blockchain: .bsc)
        }
    }

    func save(_ account: CommonAccount) {
        storage.setCurrentAccount(account: account)
        MessagingService.shared.subscribe(to: account.publicKey)
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

    private func evmGenerateKeyPair() throws -> (publicKey: Data, privateKey: Data) {
        guard
            let privateKey = SECP256K1.generatePrivateKey(),
            let publicKey = Utilities.privateToPublic(privateKey)
        else { throw AccountServiceError.errorGenerateAccount }

        return (publicKey: publicKey, privateKey: privateKey)
    }
}
