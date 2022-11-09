//
//  AccountService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import Foundation
import TweetNacl
import SolanaSwift

protocol AccountService {
    func create() throws -> Account
    func restore(by privateKey: String) throws -> Account
    func save(_ account: Account)
    func getCurrentAccount() -> Account?
}

final class AccountServiceImpl: AccountService {

    private let storage: AccountStorage

    init(storage: AccountStorage){
        self.storage = storage
    }

    func create() throws -> Account {
        let keyPair = try generateKeyPair()
        return try Account(secretKey: keyPair.privateKey)
    }

    func restore(by privateKey: String) throws -> Account {
        let privateKeyUInt8 = Base58.decode(privateKey)
        return try Account(secretKey: Data(privateKeyUInt8))
    }

    func save(_ account: Account) {
        storage.savePrivateKey(account.secretKey)
    }

    func getCurrentAccount() -> Account? {
        guard let privateKey = storage.getPrivateKey() else {
            return nil
        }
        return try? Account(secretKey: privateKey)
    }

    private func generateKeyPair() throws -> (publicKey: String, privateKey: Data) {
        let keyPair = try NaclSign.KeyPair.keyPair()
        let publicKeyString = Base58.encode(keyPair.publicKey.bytes)
        return (publicKey: publicKeyString, privateKey: keyPair.secretKey)
    }
}
