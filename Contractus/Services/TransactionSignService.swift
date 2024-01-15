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
import BigInt
import ContractusAPI

protocol TransactionDataDecodable {
    func getTxData() throws -> Data
}

enum TransactionSignServiceError: Error {
    case failed, transactionIsEmpty, invalidTransaction, invalidParameters
}

enum TxSignType {
    case byType(ContractusAPI.TransactionType)
    case common
}

protocol TransactionSignService {
    func sign(tx: TransactionDataDecodable, by signer: Signer, type: TxSignType) throws -> String
//    func sign(data: Data, by signer: Signer, type: TxSignType) throws -> String
}

final class TransactionSignServiceImpl: TransactionSignService {

    func sign(tx: TransactionDataDecodable, by signer: ContractusAPI.Signer, type: TxSignType) throws -> String {
        let data = try tx.getTxData()
        return try self.sign(data: data, by: signer, type: type)
    }
    
    private func sign(data: Data, by signer: ContractusAPI.Signer, type: TxSignType) throws -> String {
        switch type {
        case .byType(let type):
            switch type {
            case .dealInit, .dealCancel, .dealFinish:
                switch signer.blockchain {
                case .bsc:
                    let signature = try signer.signMessage(message: data)
                    return signature.toHexString().addHexPrefix()
                case .solana:
                    var tx = try Transaction.from(data: data)
                    try tx.partialSign(signers: [.init(secretKey: signer.privateKey)])
                    return try tx.serialize(requiredAllSignatures: false).base64EncodedString()
                }
            case .wrapSOL, .unwrapAllSOL, .unwrap, .wrap, .transfer:
                switch signer.blockchain {
                case .bsc:
                    fatalError("Need implementation")
                case .solana:
                    var tx = try Transaction.from(data: data)
                    try tx.partialSign(signers: [.init(secretKey: signer.privateKey)])
                    return try tx.serialize(requiredAllSignatures: false).base64EncodedString()
                }
            }
        case .common:
            switch signer.blockchain {
            case .bsc:
                let signature = try signer.sign(data: data)
                return signature.toHexString().addHexPrefix()
            case .solana:
                var tx = try Transaction.from(data: data)
                try tx.partialSign(signers: [.init(secretKey: signer.privateKey)])
                return try tx.serialize(requiredAllSignatures: false).base64EncodedString()
            }
        }
    }
}

extension ContractusAPI.Transaction: TransactionDataDecodable {
    func getTxData() throws -> Data {
        switch blockchain {
        case .bsc:
            return Data(Array(hex: self.transaction))
        case .solana:
            guard let data = Data(base64Encoded: self.transaction) else { throw TransactionSignServiceError.invalidTransaction }
            return data
        }

    }
}

extension ApprovalUnsignedTransaction: TransactionDataDecodable {
    func getTxData() throws -> Data {
        let data = Data(Array(hex: self.data))

        guard
            let to = EthereumAddress(self.to),
            let nonce = BigUInt("\(self.nonce)"),
            let chainID = BigUInt("\(self.chainId)"),
            let gasLimit = BigUInt("\(self.gasLimit)"),
            let maxFeePerGas = BigUInt(self.maxFeePerGas),
            let maxPriorityFeePerGas = BigUInt(self.maxPriorityFeePerGas) 
        else {
            throw TransactionSignServiceError.invalidParameters
        }

        let tx = CodableTransaction(
            type: .init(rawValue: self.type),
            to: to,
            nonce: nonce,
            chainID: chainID,
            data: data,
            gasLimit: gasLimit,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas
        )
        guard let hash = tx.hashForSignature() else { throw TransactionSignServiceError.invalidTransaction }
        return hash
    }
}
