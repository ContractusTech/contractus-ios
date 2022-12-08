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

struct CommonAccount: Codable, Hashable {
    let publicKeyData: Data
    let publicKey: String
    let privateKey: Data
    let blockchain: Blockchain
}

protocol WrappedAccount {
    var commonAccount: CommonAccount { get }
}

extension SolanaSwift.Account: WrappedAccount {
    var commonAccount: CommonAccount {
        .init(
            publicKeyData: self.publicKey.data,
            publicKey: self.publicKey.base58EncodedString,
            privateKey: self.secretKey,
            blockchain: .solana)
    }
}
