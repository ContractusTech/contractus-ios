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

public struct Transaction: Codable, Equatable {

    public let id: String
    public let type: TransactionType
    public let transaction: String
    public let initializerPublicKey: String
    public let amount: BigUInt?
    public let token: String?
    public let tokenAddress: String?
    public let fee: BigUInt?
    public let status: TransactionStatus

    public let ownerSignature: String?
    public let contractorSignature: String?
    public let checkerSignature: String?
    public let signature: String?

    public init(
        id: String,
        type: TransactionType,
        status: TransactionStatus,
        transaction: String,
        initializerPublicKey: String,
        amount: BigUInt? = nil,
        token: String? = nil,
        tokenAddress: String? = nil,
        ownerSignature: String? = nil,
        contractorSignature: String? = nil,
        signature: String? = nil,
        checkerSignature: String? = nil,
        fee: BigUInt? = nil)
    {
        self.id = id
        self.type = type
        self.status = status
        self.transaction = transaction
        self.amount = amount
        self.token = token
        self.tokenAddress = tokenAddress
        self.initializerPublicKey = initializerPublicKey
        self.ownerSignature = ownerSignature
        self.contractorSignature = contractorSignature
        self.checkerSignature = checkerSignature
        self.fee = fee
        self.signature = signature
    }

    enum CodingKeys: CodingKey {
        case id
        case type
        case transaction
        case initializerPublicKey
        case amount
        case token
        case tokenAddress
        case ownerSignature
        case contractorSignature
        case checkerSignature
        case fee
        case signature
        case status
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
        self.token = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.token)
        self.tokenAddress = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.tokenAddress)
        self.signature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.signature)
        self.ownerSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.ownerSignature)
        self.contractorSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.contractorSignature)
        self.checkerSignature = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.checkerSignature)
        self.status = try container.decode(TransactionStatus.self, forKey: Transaction.CodingKeys.status)

        let fee = try container.decodeIfPresent(String.self, forKey: Transaction.CodingKeys.fee)
        if let fee = fee {
            self.fee = BigUInt(stringLiteral: fee)
        } else {
            self.fee = nil
        }

    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<Transaction.CodingKeys> = encoder.container(keyedBy: Transaction.CodingKeys.self)

        try container.encode(self.id, forKey: Transaction.CodingKeys.id)
        try container.encode(self.type, forKey: Transaction.CodingKeys.type)
        try container.encode(self.transaction, forKey: Transaction.CodingKeys.transaction)
        try container.encode(self.status, forKey: Transaction.CodingKeys.status)
        try container.encode(self.initializerPublicKey, forKey: Transaction.CodingKeys.initializerPublicKey)
        try container.encodeIfPresent(self.amount, forKey: Transaction.CodingKeys.amount)
        try container.encodeIfPresent(self.fee, forKey: Transaction.CodingKeys.fee)
        try container.encodeIfPresent(self.ownerSignature, forKey: Transaction.CodingKeys.ownerSignature)
        try container.encodeIfPresent(self.contractorSignature, forKey: Transaction.CodingKeys.contractorSignature)
        try container.encodeIfPresent(self.checkerSignature, forKey: Transaction.CodingKeys.checkerSignature)
    }

    public var amountFormatted: String? {
        guard let amount = amount, let tokenCode = token else {
            return nil
        }

        return AmountFormatter.format(amount: amount, token: Token.from(code: tokenCode))
    }

    public var feeFormatted: String? {
        guard let fee = fee, !fee.isZero else {
            return nil
        }

        switch type {
        case .wrapSOL, .unwrapAllSOL:
            return AmountFormatter.format(amount: fee, token: SolanaTokens.sol)
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
