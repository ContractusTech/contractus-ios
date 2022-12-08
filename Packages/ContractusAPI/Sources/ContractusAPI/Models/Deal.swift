//
//  Deal.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import BigInt

public enum OwnerRole: String, Codable {
    case client = "CLIENT", executor = "EXECUTOR"
}

public enum DealStatus: String, Codable {
    case new = "NEW", pending = "PENDING", working = "WORKING", finished = "FINISHED", canceled = "CANCELED", unknown
}

public struct Deal: Decodable {

    enum CodingKeys: CodingKey {
        case id,
             ownerPublicKey,
             contractorPublicKey,
             checkerPublicKey,
             encryptedSecretKey,
             sharedKey,
             secretKeyHash,
             createdAt,
             amount,
             amountFee,
             currency,
             updatedAt,
             ownerRole,
             meta,
             status,
             results,
             metaUpdatedAt
    }
    public let id: String
    public var ownerPublicKey: String
    public var contractorPublicKey: String?
    public var checkerPublicKey: String?
    public let encryptedSecretKey: String?
    public let secretKeyHash: String?
    public let sharedKey: String?
    public var createdAt: String
    public var amount: BigUInt
    public var amountFee: BigUInt
    public var status: DealStatus
    public var currency: Currency
    public var updatedAt: String?
    public let ownerRole: OwnerRole
    public var meta: DealMetadata?
    public var metaUpdatedAt: String?
    public var results: DealMetadata?

    public init(
        id: String,
        ownerPublicKey: String,
        contractorPublicKey: String? = nil,
        checkerPublicKey: String? = nil,
        encryptedSecretKey: String? = nil,
        secretKeyHash: String? = nil,
        sharedKey: String? = nil,
        createdAt: String,
        amount: BigUInt,
        amountFee: BigUInt,
        status: DealStatus,
        currency: Currency,
        updatedAt: String? = nil,
        metaUpdatedAt: String? = nil,
        ownerRole: OwnerRole,
        meta: DealMetadata?,
        results: DealMetadata?)
    {
        self.id = id
        self.ownerPublicKey = ownerPublicKey
        self.contractorPublicKey = contractorPublicKey
        self.checkerPublicKey = checkerPublicKey
        self.encryptedSecretKey = encryptedSecretKey
        self.secretKeyHash = secretKeyHash
        self.sharedKey = sharedKey
        self.createdAt = createdAt
        self.amount = amount
        self.status = status
        self.currency = currency
        self.updatedAt = updatedAt
        self.ownerRole = ownerRole
        self.meta = meta
        self.results = results
        self.metaUpdatedAt = metaUpdatedAt
        self.amountFee = amountFee
    }

    public var amountFormatted: String {
        currency.format(amount: self.amount, withCode: false)
    }

    public var metadataIsEmpty: Bool {
        meta?.content?.text.isEmpty ?? true && meta?.files.isEmpty ?? true
    }

    public var resultsIsEmpty: Bool {
        results?.content?.text.isEmpty ?? true && results?.files.isEmpty ?? true
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.ownerPublicKey = try container.decode(String.self, forKey: .ownerPublicKey)
        self.contractorPublicKey = try? container.decodeIfPresent(String.self, forKey: .contractorPublicKey)
        self.checkerPublicKey = try? container.decodeIfPresent(String.self, forKey: .checkerPublicKey)
        self.encryptedSecretKey = try? container.decodeIfPresent(String.self, forKey: .encryptedSecretKey)
        self.secretKeyHash = try? container.decodeIfPresent(String.self, forKey: .secretKeyHash)
        self.sharedKey = try? container.decodeIfPresent(String.self, forKey: .sharedKey)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        let amount = try container.decode(String.self, forKey: .amount)
        self.amount = BigUInt(stringLiteral: amount)
        let currency = try container.decode(String.self, forKey: .currency)
        self.currency = Currency.from(code: currency)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.ownerRole = try container.decode(OwnerRole.self, forKey: .ownerRole)
        self.meta = try? container.decodeIfPresent(DealMetadata.self, forKey: .meta)
        self.results = try? container.decodeIfPresent(DealMetadata.self, forKey: .results)
        self.metaUpdatedAt = try? container.decodeIfPresent(String.self, forKey: .metaUpdatedAt)
        self.status = (try? container.decodeIfPresent(DealStatus.self, forKey: .status)) ?? .unknown
        let amountFee = (try? container.decode(String.self, forKey: .amountFee)) ?? "0"
        self.amountFee = BigUInt(stringLiteral: amountFee)
    }
}

public struct NewDeal: Encodable {
    public let role: OwnerRole
    public let encryptedSecretKey: String
    public let secretKeyHash: String
    public let sharedKey: String

    public init(role: OwnerRole, encryptedSecretKey: String, secretKeyHash: String, sharedKey: String) {
        self.role = role
        self.encryptedSecretKey = encryptedSecretKey
        self.secretKeyHash = secretKeyHash
        self.sharedKey = sharedKey
    }

}


public struct DealTransaction: Codable {
    public let type: TransactionType
    public let transaction: String
}

public struct SignedDealTransaction: Codable {

    public let transaction: String

    public init(transaction: String) {
        self.transaction = transaction
    }

}

public struct UpdateAmountDeal: Codable {

    let amount: Amount
    let feeAmount: Amount

    public init(amount: Amount, feeAmount: Amount) {
        self.amount = amount
        self.feeAmount = feeAmount
    }

}

public struct CancelDeal: Codable {
    let force: Bool
}


public enum TransactionType: String, Codable {
    case `init` = "INIT", finish = "FINISH", cancel = "CANCEL"
}

public struct CalculateDealFee: Codable {
    public let amount: Amount
    
    public init(amount: Amount) {
        self.amount = amount
    }
}

public struct DealFee: Codable {
    public let feeAmount: Amount
    public let fee: Double
}
