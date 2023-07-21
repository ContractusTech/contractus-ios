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
    func isSigned(txBase64: String, publicKeys: [PublicKey]) -> [PublicKey]
}

final class SolanaTransactionSignServiceImpl: TransactionSignService {

    enum TransactionSignServiceError: Error {
        case failed, transactionIsEmpty
    }

    /// Return signed Transaction as Base64 string and Signature
    func sign(txBase64: String, by secretKey: Data) throws -> (signature: String, message: String) {
        guard !txBase64.isEmpty else {
            throw TransactionSignServiceError.transactionIsEmpty
        }
        guard let account = try? KeyPair(secretKey: secretKey), let dataToSign = Data(base64Encoded: txBase64) else {
            throw TransactionSignServiceError.failed
        }

        var tx = try Transaction.from(data: dataToSign)
        do {
            try tx.partialSign(signers: [account])
        } catch {
            debugPrint(error.localizedDescription)
            throw error
        }

        guard let sign = tx.signatures.last(where: {$0.publicKey == account.publicKey}) else {
            throw TransactionSignServiceError.failed
        }
        guard let signBase64 = sign.signature?.base64EncodedString() else {
            throw TransactionSignServiceError.failed
        }
        return (signBase64, try tx.serialize(requiredAllSignatures: false).base64EncodedString())
    }

    func isSigned(txBase64: String, publicKey: Data) -> Bool {
        guard let dataToSign = Data(base64Encoded: txBase64), let publicKey = try? PublicKey(data: publicKey) else { return false }
        return _isSigned(txData: dataToSign, publicKey: publicKey)
    }

    func isSigned(txBase64: String, publicKeys: [PublicKey]) -> [PublicKey] {
        guard let dataToSign = Data(base64Encoded: txBase64) else { return [] }
        return publicKeys.compactMap { publicKey in
            guard _isSigned(txData: dataToSign, publicKey: publicKey) else { return nil }
            return publicKey
        }
    }

    private func _isSigned(txData: Data, publicKey: PublicKey) -> Bool {
        let tx = try? Transaction.from(data: txData)
        return tx?.signatures.first(where: {$0.publicKey == publicKey && $0.signature != nil}) != nil
    }
}
