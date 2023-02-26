//
//  TxSign.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.09.2022.
//

import Foundation
import SolanaSwift
import TweetNacl

protocol TransactionSignService {
    func sign(txBase64: String, by secretKey: Data) throws -> (signature: String, message: String)
    func isSigned(txBase64: String, publicKey: Data) -> Bool
}

final class SolanaTransactionSignServiceImpl: TransactionSignService {

    enum TransactionSignServiceError: Error {
        case failed
    }

    /// Return signed Transaction as Base64 string and Signature
    func sign(txBase64: String, by secretKey: Data) throws -> (signature: String, message: String) {
        guard let account = try? Account(secretKey: secretKey), let dataToSign = Data(base64Encoded: txBase64) else {
            throw TransactionSignServiceError.failed
        }

        var tx = try Transaction.from(data: dataToSign)
        try tx.partialSign(signers: [account])
        guard let sign = tx.signatures.last(where: {$0.publicKey == account.publicKey}) else {
            throw TransactionSignServiceError.failed
        }

        guard let signBase64 = sign.signature?.base64EncodedString() else {
            throw TransactionSignServiceError.failed
        }
        return (signBase64, try tx.serialize().base64EncodedString())
    }

    func isSigned(txBase64: String, publicKey: Data) -> Bool {
        
        guard let dataToSign = Data(base64Encoded: txBase64), let publicKey = try? PublicKey(data: publicKey) else { return false }
        var tx = try? Transaction.from(data: dataToSign)
        return tx?.signatures.first(where: {$0.publicKey == publicKey && $0.signature != nil}) != nil
    }
}
