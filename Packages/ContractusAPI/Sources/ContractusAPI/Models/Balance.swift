//
//  Balance.swift
//  
//
//  Created by Simon Hudishkin on 26.09.2022.
//

import Foundation
import BigInt

public struct Balance: Decodable {

    public enum Tier: String, Decodable {
        case basic, holder
    }

    public struct TokenInfo: Decodable {

        public let price: Double
        public let priceFormatted: String
        public let priceFormattedWithCode: String
        public let currency: Currency
        public let amount: Amount

        public init(price: Double, currency: Currency, amount: Amount) {
            self.price = price
            self.currency = currency
            self.amount = amount
            self.priceFormatted = currency.format(double: price, withCode: false) ?? ""
            self.priceFormattedWithCode = currency.format(double: price, withCode: true) ?? ""
        }

        enum CodingKeys: CodingKey {
            case price
            case currency
            case amount
        }

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<Balance.TokenInfo.CodingKeys> = try decoder.container(keyedBy: Balance.TokenInfo.CodingKeys.self)

            self.price = try container.decode(Double.self, forKey: Balance.TokenInfo.CodingKeys.price)
            let currency = try container.decode(String.self, forKey: Balance.TokenInfo.CodingKeys.currency)
            self.currency = .from(code: currency)
            self.amount = try container.decode(Amount.self, forKey: Balance.TokenInfo.CodingKeys.amount)

            self.priceFormatted = self.currency.format(double: price, withCode: false) ?? ""
            self.priceFormattedWithCode = self.currency.format(double: price, withCode: true) ?? ""

        }
    }

    public let estimateAmount: Double
    public let blockchain: String
    public let tokens: [TokenInfo]
    public let wrap: [String]
    public let tier: Tier

    public init(estimateAmount: Double, tokens: [TokenInfo], blockchain: String, wrap: [String], tier: Tier) {
        self.estimateAmount = estimateAmount
        self.tokens = tokens
        self.blockchain = blockchain
        self.wrap = wrap
        self.tier = tier
    }

    enum CodingKeys: CodingKey {
        case estimateAmount
        case blockchain
        case tokens
        case wrap
        case tier
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Balance.CodingKeys> = try decoder.container(keyedBy: Balance.CodingKeys.self)

        self.estimateAmount = try container.decode(Double.self, forKey: Balance.CodingKeys.estimateAmount)
        self.blockchain = try container.decode(String.self, forKey: Balance.CodingKeys.blockchain)
        self.tokens = try container.decode([Balance.TokenInfo].self, forKey: Balance.CodingKeys.tokens)
        self.wrap = try container.decode([String].self, forKey: Balance.CodingKeys.wrap)
        self.tier = try container.decode(Tier.self, forKey: Balance.CodingKeys.tier)

    }
}
