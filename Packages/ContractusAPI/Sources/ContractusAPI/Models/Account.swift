//
//  Account.swift
//  
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import Foundation

public struct Account: Decodable {

    public let publicKey: String
    public let blockchain: String
    public let createdAt: String
    public let isPublic: Bool
    public let displayName: String?
    public let description: String?
    public let encryptedSecretKey: String?

    public init(publicKey: String, blockchain: String, createdAt: String, isPublic: Bool, displayName: String? = nil, description: String? = nil, encryptedSecretKey: String? = nil) {
        self.publicKey = publicKey
        self.blockchain = blockchain
        self.createdAt = createdAt
        self.isPublic = isPublic
        self.displayName = displayName
        self.description = description
        self.encryptedSecretKey = encryptedSecretKey
    }
}

public struct AccountStatistic: Decodable {

    enum CodingKeys: CodingKey {
        case type, amount, currency
    }

    public enum ItemType: String, Decodable {
        case locked = "LOCKED", revenue30d = "REVENUE_30", revenueAll = "REVENUE_ALL", paid30d = "PAID_30", paidAll = "PAID_ALL"
    }

    public let type: ItemType
    public let amount: Double
    public let currency: Currency

    public init(type: AccountStatistic.ItemType, amount: Double, currency: Currency) {
        self.type = type
        self.amount = amount
        self.currency = currency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(ItemType.self, forKey: CodingKeys.type)
        amount = try container.decode(Double.self, forKey: CodingKeys.amount)
        let currency = try container.decode(String.self, forKey: CodingKeys.currency)
        self.currency = Currency.availableCurrencies.first { $0.code == currency }!
    }


}
