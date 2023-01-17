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
    func signIfNeeded(txBase64: String, by secretKey: Data) throws -> (signature: String, signedMessage: String)
    func isSigned(txBase64: String, signatureBase64: String, publicKey: Data) -> Bool
}

final class SolanaTransactionSignServiceImpl: TransactionSignService {

    enum TransactionSignServiceError: Error {
        case failed
    }

    /// Return signed Transaction as Base64 string and Signature
    func signIfNeeded(txBase64: String, by secretKey: Data) throws -> (signature: String, signedMessage: String) {
        guard let account = try? Account(secretKey: secretKey), let dataToSign = Data(base64Encoded: txBase64) else {
            throw TransactionSignServiceError.failed
        }

        guard let signature = try? NaclSign.signDetached(message: dataToSign, secretKey: secretKey) else {
            throw TransactionSignServiceError.failed
        }
        let signed = try NaclSign.signDetachedVerify(message: dataToSign, sig: signature, publicKey: account.publicKey.data)
        if signed {
            return (signature.base64EncodedString(), txBase64)
        }

        guard let signedMessage = try? NaclSign.sign(message: dataToSign, secretKey: secretKey)
        else {
            throw TransactionSignServiceError.failed

        }
        return (signature.base64EncodedString(), signedMessage.base64EncodedString())
    }

    func isSigned(txBase64: String, signatureBase64: String, publicKey: Data) -> Bool {
        guard let dataToSign = Data(base64Encoded: txBase64), let signature = Data(base64Encoded: signatureBase64) else { return false }
        let signed = try? NaclSign.signDetachedVerify(message: dataToSign, sig: signature, publicKey: publicKey)
        return signed ?? false
    }
}
