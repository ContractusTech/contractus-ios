//
//  Transaction.swift
//  
//
//  Created by Simon Hudishkin on 02.02.2023.
//

import Foundation
import BigInt

public enum TransactionStatus: String, Codable {
    case new = "NEW", processing = "IN_PROCESSING", finished = "FINISHED", error = "ERROR"
}

public struct Transaction: Decodable, Equatable {

    public struct ErrorDetail: Decodable, Equatable {
        public let name: String
        public let message: String?
    }

    public let id: String
    public let type: TransactionType
    public let transaction: String
    public let initializerPublicKey: String
    public let amount: BigUInt?
    public let token: Token?
    public let fee: BigUInt?
    public let status: TransactionStatus

    public let ownerSignature: String?
    public let contractorSignature: String?
    public let checkerSignature: String?
    public let signature: String?
    public let errorDetail: ErrorDetail?

    public init(
        id: String,
        type: TransactionType,
        status: TransactionStatus,
        transaction: String,
        initializerPublicKey: String,
        amount: BigUInt? = nil,
        token: Token? = nil,
//        tokenAddress: String? = nil,
        ownerSignature: String? = nil,
        contractorSignature: String? = nil,
        signature: String? = nil,
        checkerSignature: String? = nil,
        fee: BigUInt? = nil,
        errorDetail: ErrorDetail? = nil
    ){
        self.id = id
        self.type = type
        self.status = status
        self.transaction = transaction
        self.amount = amount
        self.token = token
//        self.tokenAddress = tokenAddress
        self.initializerPublicKey = initializerPublicKey
        self.ownerSignature = ownerSignature
        self.contractorSignature = contractorSignature
        self.checkerSignature = checkerSignature
        self.fee = fee
        self.signature = signature
        self.errorDetail = errorDetail
    }

    enum CodingKeys: CodingKey {
        case id
        case type
        case transaction
        case initializerPublicKey
        case amount
        case token
//        case tokenAddress
        case ownerSignature
        case contractorSignature
        case checkerSignature
        case fee
        case signature
        case status
        case details
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Transaction.CodingKeys> = try decoder.container(keyedBy: Transaction.CodingKeys.self)

        self.id = try container.decode(String.self, forKey: Transaction.CodingKeys.id)
        self.type = try container.decode(TransactionType.self, forKey: Transaction.CodingKeys.type)
        self.transaction = (try? container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.transaction)) ?? "" // TODO: - Fix this
        self.initializerPublicKey = try container.decode(String.self, forKey: Transaction.CodingKeys.initializerPublicKey)
        let amount = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.amount)
        if let amount = amount {
            self.amount = BigUInt(stringLiteral: amount)
        } else {
            self.amount = nil
        }
        self.token = try container.decodeIfPresent(Token.self, forKey: Transaction.CodingKeys.token)
//        self.tokenAddress = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.tokenAddress)
        self.signature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.signature)
        self.ownerSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.ownerSignature)
        self.contractorSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.contractorSignature)
        self.checkerSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.checkerSignature)
        self.status = try container.decode(TransactionStatus.self, forKey: Transaction.CodingKeys.status)

        if let errorDetail = try? container.decode(ErrorDetail.self, forKey: Transaction.CodingKeys.details) {
            self.errorDetail = errorDetail
        } else {
            self.errorDetail = nil
        }

        let fee = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.fee)
        if let fee = fee {
            self.fee = BigUInt(stringLiteral: fee)
        } else {
            self.fee = nil
        }
    }

    public var amountFormatted: String? {
        guard let amount = amount, let token = token else {
            return nil
        }

        return AmountFormatter.format(amount: amount, token: token)
    }

    public var feeFormatted: String? {
        guard let fee = fee, !fee.isZero, let token = token else {
            return nil
        }

        switch type {
        case .wrapSOL, .unwrapAllSOL:
            return AmountFormatter.format(amount: fee, token: token)
        case .dealCancel, .dealInit, .dealFinish:
            return nil
        }
    }
}

public struct SignedTransaction: Codable {

    public let transaction: String
    public let signature: String

    public init(transaction: String, signature: String) {
        self.transaction = transaction
        self.signature = signature
    }
}
