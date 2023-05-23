//
//  Deal.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import BigInt

public enum PerformanceBondType: String, Codable {
    case onlyClient = "ONLY_CLIENT", onlyExecutor = "ONLY_EXECUTOR", both = "BOTH", none = "NONE"
}

public enum CompletionCheckType: String, Codable {
    case checker = "CHECKER", none = "NONE"
}

public enum OwnerRole: String, Codable {
    case client = "CLIENT", executor = "EXECUTOR"
}

public enum DealStatus: String, Codable {
    case new = "NEW", pending = "PENDING", working = "WORKING", finished = "FINISHED", canceled = "CANCELED", inProcessing = "IN_PROCESSING", unknown
}

public struct Deal: Decodable {

    enum CodingKeys: CodingKey {
        case id,
             performanceBondType,
             completionCheckType,
             ownerPublicKey,
             contractorPublicKey,
             checkerPublicKey,
             encryptedSecretKey,
             sharedKey,
             secretKeyHash,
             createdAt,
             amount,
             amountFee,
             checkerAmount,
             token,
             tokenAddress,
             updatedAt,
             ownerRole,
             meta,
             status,
             result,
             metaUpdatedAt,
             ownerBondAmount,
             ownerBondToken,
             contractorBondAmount,
             contractorBondToken
    }
    public let id: String
    public let completionCheckType: CompletionCheckType
    public let performanceBondType: PerformanceBondType
    public var ownerPublicKey: String
    public var contractorPublicKey: String?
    public var checkerPublicKey: String?
    public let encryptedSecretKey: String?
    public let secretKeyHash: String?
    public let sharedKey: String?
    public var createdAt: String
    public var amount: BigUInt
    public var amountFee: BigUInt
    public var checkerAmount: BigUInt?
    public var status: DealStatus
    public var token: Token
    public var updatedAt: String?
    public let ownerRole: OwnerRole
    public var meta: DealMetadata?
    public var metaUpdatedAt: String?
    public var result: DealMetadata?

    public var ownerBondAmount: BigUInt?
    public var ownerBondToken: Token?

    public var contractorBondAmount: BigUInt?
    public var contractorBondToken: Token?


    public init(
        id: String,
        completionCheckType: CompletionCheckType,
        performanceBondType: PerformanceBondType,
        ownerPublicKey: String,
        contractorPublicKey: String? = nil,
        checkerPublicKey: String? = nil,
        encryptedSecretKey: String? = nil,
        secretKeyHash: String? = nil,
        sharedKey: String? = nil,
        createdAt: String,
        amount: BigUInt,
        amountFee: BigUInt,
        checkerAmount: BigUInt?,
        status: DealStatus,
        token: Token,
        updatedAt: String? = nil,
        metaUpdatedAt: String? = nil,
        ownerRole: OwnerRole,
        meta: DealMetadata?,
        result: DealMetadata?,
        ownerBondAmount: BigUInt? = nil,
        ownerBondToken: Token? = nil,
        contractorBondAmount: BigUInt? = nil,
        contractorBondToken: Token? = nil)
    {
        self.id = id
        self.performanceBondType = performanceBondType
        self.completionCheckType = completionCheckType
        self.ownerPublicKey = ownerPublicKey
        self.contractorPublicKey = contractorPublicKey
        self.checkerPublicKey = checkerPublicKey
        self.encryptedSecretKey = encryptedSecretKey
        self.secretKeyHash = secretKeyHash
        self.sharedKey = sharedKey
        self.createdAt = createdAt
        self.amount = amount
        self.status = status
        self.token = token
        self.updatedAt = updatedAt
        self.ownerRole = ownerRole
        self.meta = meta
        self.result = result
        self.metaUpdatedAt = metaUpdatedAt
        self.amountFee = amountFee
        self.checkerAmount = checkerAmount
        self.ownerBondToken = ownerBondToken
        self.contractorBondToken = contractorBondToken
        self.ownerBondAmount = ownerBondAmount
        self.contractorBondAmount = contractorBondAmount
    }

    public var amountFormatted: String {
        token.format(amount: self.amount, withCode: false)
    }

    public var ownerBondFormatted: String {
        ownerBondToken?.format(amount: self.ownerBondAmount ?? BigUInt(), withCode: false) ?? ""
    }

    public var contractorBondFormatted: String {
        contractorBondToken?.format(amount: self.contractorBondAmount ?? BigUInt(), withCode: false) ?? ""
    }

    public var metadataIsEmpty: Bool {
        meta?.content?.text.isEmpty ?? true && meta?.files.isEmpty ?? true
    }

    public var resultIsEmpty: Bool {
        result?.content?.text.isEmpty ?? true && result?.files.isEmpty ?? true
    }

    public var amountFeeFormatted: String {
        token.format(amount: self.amountFee, withCode: false)
    }

    public var amountFeeCheckerFormatted: String? {
        if let checkerAmount = checkerAmount {
            return token.format(amount: checkerAmount, withCode: false)
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.ownerPublicKey = try container.decode(String.self, forKey: .ownerPublicKey)
        self.completionCheckType = try container.decode(CompletionCheckType.self, forKey: .completionCheckType)
        self.performanceBondType = try container.decode(PerformanceBondType.self, forKey: .performanceBondType)
        self.contractorPublicKey = try? container.decodeIfPresent(String.self, forKey: .contractorPublicKey)
        self.checkerPublicKey = try? container.decodeIfPresent(String.self, forKey: .checkerPublicKey)
        self.encryptedSecretKey = try? container.decodeIfPresent(String.self, forKey: .encryptedSecretKey)
        self.secretKeyHash = try? container.decodeIfPresent(String.self, forKey: .secretKeyHash)
        self.sharedKey = try? container.decodeIfPresent(String.self, forKey: .sharedKey)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        let amount = try container.decode(String.self, forKey: .amount)
        self.amount = BigUInt(stringLiteral: amount)
        self.token = try container.decode(Token.self, forKey: .token)
        self.updatedAt = try? container.decodeIfPresent(String.self, forKey: .updatedAt)
        self.ownerRole = try container.decode(OwnerRole.self, forKey: .ownerRole)
        self.meta = try? container.decodeIfPresent(DealMetadata.self, forKey: .meta)
        self.result = try? container.decodeIfPresent(DealMetadata.self, forKey: .result)
        self.metaUpdatedAt = try? container.decodeIfPresent(String.self, forKey: .metaUpdatedAt)
        self.status = (try? container.decodeIfPresent(DealStatus.self, forKey: .status)) ?? .unknown
        let amountFee = (try? container.decode(String.self, forKey: .amountFee)) ?? "0"
        self.amountFee = BigUInt(stringLiteral: amountFee)

        if let checkerAmount = (try? container.decode(String.self, forKey: .checkerAmount)) {
            self.checkerAmount = BigUInt(stringLiteral: checkerAmount)
        }

        if let ownerBondAmount = try? container.decode(String.self, forKey: .ownerBondAmount) {
            self.ownerBondAmount = BigUInt(stringLiteral: ownerBondAmount)
        }

        if let contractorBondAmount = try? container.decode(String.self, forKey: .contractorBondAmount) {
            self.contractorBondAmount = BigUInt(stringLiteral: contractorBondAmount)
        }

        self.ownerBondToken = try? container.decodeIfPresent(Token.self, forKey: .ownerBondToken)
        self.contractorBondToken = try? container.decodeIfPresent(Token.self, forKey: .contractorBondToken)
    }

    public func getPartnersBy(_ publicKey: String) -> String? {
        if self.ownerPublicKey == publicKey {
            return self.contractorPublicKey
        }
        return ownerPublicKey
    }
}

extension Deal: Equatable {}

public struct NewDeal: Encodable {
    public let role: OwnerRole
    public let encryptedSecretKey: String
    public let secretKeyHash: String
    public let sharedKey: String
    public let performanceBondType: PerformanceBondType
    public let completionCheckType: CompletionCheckType

    public init(role: OwnerRole, encryptedSecretKey: String, secretKeyHash: String, sharedKey: String, performanceBondType: PerformanceBondType, completionCheckType: CompletionCheckType) {
        self.role = role
        self.encryptedSecretKey = encryptedSecretKey
        self.secretKeyHash = secretKeyHash
        self.sharedKey = sharedKey
        self.performanceBondType = performanceBondType
        self.completionCheckType = completionCheckType
    }

}

public struct UpdateDeal: Codable {

    let amount: Amount?
    let checkerAmount: Amount?
    let ownerBondAmount: Amount?
    let contractorBondAmount: Amount?

    public init(amount: Amount?, checkerAmount: Amount?, ownerBondAmount: Amount?, contractorBondAmount: Amount?) {
        self.amount = amount
        self.checkerAmount = checkerAmount
        self.ownerBondAmount = ownerBondAmount
        self.contractorBondAmount = contractorBondAmount
    }

}

public struct CancelDeal: Codable {
    let force: Bool
}

public enum TransactionType: String, Codable {
    case dealInit = "DEAL_INIT", dealFinish = "DEAL_FINISH", dealCancel = "DEAL_CANCELED", wrapSOL = "WRAP_SOL", unwrapAllSOL = "UNWRAP_ALL_SOL"
}

public enum AmountFeeType: String, Codable {
    case dealAmount = "DEAL", checkerAmount = "CHECKER"
}

public struct CalculateDealFee: Codable {
    public let amount: Amount
    public let type: AmountFeeType

    public init(amount: Amount, type: AmountFeeType) {
        self.amount = amount
        self.type = type
    }
}

public struct DealFee: Decodable {
    public let allow: Bool
    public let feeAmount: Amount
    public let fiatFee: Double
    public let fiatCurrency: Currency
    public let isMinimum: Bool
    public let percent: Double
    public let type: AmountFeeType

    enum CodingKeys: CodingKey {
        case feeAmount
        case fiatFee
        case fiatCurrency
        case isMinimum
        case percent
        case type
        case allow
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<DealFee.CodingKeys> = try decoder.container(keyedBy: DealFee.CodingKeys.self)

        self.allow = try container.decode(Bool.self, forKey: DealFee.CodingKeys.allow)
        self.feeAmount = try container.decode(Amount.self, forKey: DealFee.CodingKeys.feeAmount)
        self.fiatFee = try container.decode(Double.self, forKey: DealFee.CodingKeys.fiatFee)
        let fiatCurrency = try container.decode(String.self, forKey: DealFee.CodingKeys.fiatCurrency)
        self.fiatCurrency = Currency.from(code: fiatCurrency)
        self.isMinimum = try container.decode(Bool.self, forKey: DealFee.CodingKeys.isMinimum)
        self.percent = try container.decode(Double.self, forKey: DealFee.CodingKeys.percent)
        self.type = try container.decode(AmountFeeType.self, forKey: DealFee.CodingKeys.type)
    }
}
