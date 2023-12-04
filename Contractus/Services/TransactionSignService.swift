//
//  TxSign.swift
//  Contractus
//
//  Created by Simon Hudishkin on 08.09.2022.
//

import Foundation
import SolanaSwift
import TweetNacl
import Web3Core
import ContractusAPI

protocol TransactionSignService {
//    func sign(txBase64: String, by secretKey: Data) throws -> (signature: String, message: String)
//    func isSigned(txBase64: String, publicKey: Data) -> Bool
//    func isSigned(txBase64: String, publicKeys: [PublicKey]) -> [PublicKey]

    func sign(type: ContractusAPI.TransactionType, data: Data, by signer: Signer) throws -> Data
}

final class TransactionSignServiceImpl: TransactionSignService {
    func sign(type: ContractusAPI.TransactionType, data: Data, by signer: ContractusAPI.Signer) throws -> Data {
        switch type {
        case .dealInit, .dealCancel, .dealFinish:
            switch signer.blockchain {
            case .bsc:
                let signature = try signer.sign(data: data)
                return signature
            case .solana:
                var tx = try Transaction.from(data: data)
                try tx.partialSign(signers: [.init(secretKey: signer.privateKey)])
                return try tx.serialize(requiredAllSignatures: false)
            }
        case .wrapSOL, .unwrapAllSOL, .unwrap, .wrap, .transfer:
            switch signer.blockchain {
            case .bsc:
                fatalError("Need implementation")
            case .solana:
                var tx = try Transaction.from(data: data)
                try tx.partialSign(signers: [.init(secretKey: signer.privateKey)])
                return try tx.serialize(requiredAllSignatures: false)
            }
        }


    }
    

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


//class EVMSignerService {
//    
//    var signer: Signer
//
//    init(signer: Signer) {
//        self.signer = signer
//    }
//
//    func sigmMessage(types: [ABI.Element.InOut], values: [Any]) -> Data? {
//        let message = ABIEncoder.encode(types: types, values: values)
//        guard let message = message else { return nil }
//        let messagePack = ABIEncoder.encode(types: [.dynamicBytes], values: [message])
//        guard let messagePack = messagePack else { return nil }
//        let messageHash = messagePack.sha3(.keccak256)
//
//        return try? signer.sign(data: messageHash)
//    }
//}
