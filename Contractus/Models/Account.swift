//
//  Account.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.08.2022.
//

import Foundation
import TweetNacl
import Base58Swift
import SolanaSwift
import ContractusAPI
import Web3Core

struct CommonAccount: Codable, Hashable {
    let publicKeyData: Data
    let publicKey: String
    let privateKey: Data
    let blockchain: Blockchain
}

extension CommonAccount {
    func privateKeyEncoded() -> String {
        switch blockchain {
        case .solana:
            return privateKey.toBase58()
        case .bsc:
            return privateKey.toHexString()
        }
    }
}

protocol WrappedAccount {
    var commonAccount: CommonAccount { get }
}

extension SolanaSwift.KeyPair: WrappedAccount {
    var commonAccount: CommonAccount {
        .init(
            publicKeyData: self.publicKey.data,
            publicKey: self.publicKey.base58EncodedString,
            privateKey: self.secretKey,
            blockchain: .solana)
    }
}
