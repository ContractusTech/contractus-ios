//
//  Amount.swift
//  
//
//  Created by Simon Hudishkin on 18.08.2022.
//

import Foundation
import BigInt


public struct Amount {

    public let value: BigUInt
    public let currency: Currency

    public init(_ value: BigUInt, currency: Currency) {
        self.value = value
        self.currency = currency
    }

    public init(_ value: String, currency: Currency) {
        self.value = currency.format(string: value) ?? BigUInt(0)
        self.currency = currency
    }

    public init(_ value: UInt64, currency: Currency) {
        self.value = BigUInt(value)
        self.currency = currency
    }

    public func formatted() -> String {
        currency.format(amount: value, withCode: false)
    }

    public static func isValid(_ value: String, currency: Currency) -> Bool {
        guard currency.format(string: value) != nil else { return false }
        return true
    }
}

extension Amount: Codable {

    enum CodingKeys: CodingKey {
        case value, currency
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value.description, forKey: .value)
        try container.encode(currency.code, forKey: .currency)
    }
}
