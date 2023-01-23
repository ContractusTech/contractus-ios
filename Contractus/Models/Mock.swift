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
        return Deal(id: "", ownerPublicKey: "", createdAt: "", amount: "10000000", amountFee: "100", checkerAmount: nil, status: .new, currency: .sol, ownerRole: .client, meta: DealMetadata(files: []), results: DealMetadata(files: []))
    }


    static let privateKeyUInt8 = Array<UInt8>(repeating: 0, count: 32)
    static let privateKeyData: Data = Data(privateKeyUInt8)
    static let fileRaw = RawFile(data: Data(), name: "Mockfile", mimeType: "image")
    static let metadataFile = MetadataFile(md5: "123", url: URL(string: "http://ya.ru")!, name: "File Test", encrypted: false, size: 100000)
    static let metadataFileLock = MetadataFile(md5: "123", url: URL(string: "http://ya.ru")!, name: "File Test", encrypted: true, size: 100000)
    static let encryptedTextBase64 = "YMKC9mwc5X1MpnB919rRZA=="
}
