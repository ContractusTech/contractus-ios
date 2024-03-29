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
    static let account: CommonAccount = {
        let secret = try! TweetNacl.NaclSign.KeyPair.keyPair().secretKey
        return (try! Account(secretKey: secret)).commonAccount
    }()

    static let deal: ContractusAPI.Deal = {
        return Deal(id: "", completionCheckType: .checker, performanceBondType: .both, ownerPublicKey: "", createdAt: Date(), amount: "10000000", amountFee: "100", checkerAmount: nil, status: .new, token: Self.tokenSOL, ownerRole: .client, meta: DealMetadata(files: []), result: DealMetadata(files: []))
    }()

    static let wrapTransaction: ContractusAPI.Transaction = {
        return ContractusAPI.Transaction(id: "123", type: .wrapSOL, status: .new, transaction: "123123123", blockchain: .solana, initializerPublicKey: account.publicKey, ownerSignature: nil, contractorSignature: nil, checkerSignature: nil)
    }()

    static let wrapTransactionProcessing: ContractusAPI.Transaction = {
        return ContractusAPI.Transaction(id: "123", type: .wrapSOL, status: .processing, transaction: "123123123", blockchain: .solana, initializerPublicKey: account.publicKey, ownerSignature: nil, contractorSignature: nil, signature: "123123123123123123", checkerSignature: nil)
    }()

    static let tokenList: [ContractusAPI.Token] = [Self.tokenSOL, Self.tokenWSOL, Self.tokenCTUS]

    static let tokenEmpty = Token(code: "", name: "", native: true, decimals: 9, serviced: false)
    static let tokenSOL = Token(code: "SOL", name: "Solana", native: true, decimals: 9, serviced: false)
    static let tokenWSOL = Token(code: "WSOL", name: "WSolana", native: false, decimals: 9, serviced: false)
    static let tokenCTUS = Token(code: "CTUS", name: "Contractus", native: false, decimals: 9, serviced: true, holderMode: true)

    static let privateKeyUInt8 = Array<UInt8>(repeating: 0, count: 32)
    static let privateKeyData: Data = Data(privateKeyUInt8)
    static let fileRaw = RawFile(data: Data(), name: "Mockfile", mimeType: "image")
    static let metadataFile = MetadataFile(md5: "123", url: URL(string: "http://ya.ru")!, name: "File Test", encrypted: false, size: 100000)
    static let metadataFileLock = MetadataFile(md5: "123", url: URL(string: "http://ya.ru")!, name: "File Test", encrypted: true, size: 100000)
    static let encryptedTextBase64 = "YMKC9mwc5X1MpnB919rRZA=="
}
