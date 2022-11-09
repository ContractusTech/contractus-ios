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
    func sign(txBase64: String, by secretKey: Data) throws -> String
}

final class SolanaTransactionSignServiceImpl: TransactionSignService {

    enum TransactionSignServiceError: Error {
        case failed
    }

    func sign(txBase64: String, by secretKey: Data) throws -> String {
        guard let account = try? Account(secretKey: secretKey) else {
            throw TransactionSignServiceError.failed
        }
        guard
            let dataToSign = Data(base64Encoded: txBase64),
            let signature = try? NaclSign.signDetached(message: dataToSign, secretKey: account.secretKey)
        else {
//
//            // Check if already signed (Need check!!!)
//            if
//                let dataTx = Data(base64Encoded: txBase64),
//                let signature = try? NaclSign.signOpen(signedMessage: dataTx, publicKey: account.publicKey.data)
//            {
//                return signature.base64EncodedString()
//
//            }

            throw TransactionSignServiceError.failed

        }

        return signature.base64EncodedString()
    }
}
