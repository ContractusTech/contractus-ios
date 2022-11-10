//
//  Mock.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.08.2022.
//
import Foundation
import SolanaSwift
import TweetNacl
import ContractusAPI

enum Mock {
    static var account: CommonAccount {
        let secret = try! TweetNacl.NaclSign.KeyPair.keyPair().secretKey
        return (try! Account(secretKey: secret)).commonAccount
    }

    static var deal: ContractusAPI.Deal {
        return Deal(id: "", ownerPublicKey: "", createdAt: "", amount: "10000", currency: .sol, ownerRole: .client, meta: DealMetadata(files: []), results: DealMetadata(files: []))
    }


    static let privateKeyUInt8 = Array<UInt8>(repeating: 0, count: 32)
    static let privateKeyData: Data = Data(privateKeyUInt8)

    static let encryptedTextBase64 = "YMKC9mwc5X1MpnB919rRZA=="
}
