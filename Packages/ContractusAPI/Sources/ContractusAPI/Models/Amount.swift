//
//  Amount.swift
//  
//
//  Created by Simon Hudishkin on 18.08.2022.
//

import Foundation
import BigInt

public struct AmountValue: Encodable {
    public let value: BigUInt

    public init(_ value: String, decimals: Int) {
        self.value = AmountFormatter.format(string: value, decimal: decimals) ?? BigUInt(0)
    }

    public init(_ value: BigUInt) {
        self.value = value
    }

    public init(_ value: UInt64, decimals: Int) {
        self.value = AmountFormatter.format(string: String(value), decimal: decimals) ?? BigUInt(0)
    }

    enum CodingKeys: CodingKey {
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value.description, forKey: .value)
    }
}

public struct Amount: Equatable {

    public let value: BigUInt
    public let token: Token

    public init(_ value: BigUInt, token: Token) {
        self.value = value
        self.token = token
    }

    public init(_ value: String, token: Token) {
        self.value = AmountFormatter.format(string: value, token: token) ?? BigUInt(0)
        self.token = token
    }

    public init(_ value: UInt64, token: Token) {
        self.value = BigUInt(value)
        self.token = token
    }

    public func formatted(withCode: Bool = false) -> String {
        AmountFormatter.format(amount: value, decimal: token.decimals, code: withCode ? token.code : nil)
    }

    public static func isValid(_ value: String, token: Token) -> Bool {
        guard AmountFormatter.format(string: value, token: token) != nil else { return false }
        return true
    }
}

extension Amount: Codable {

    enum CodingKeys: CodingKey {
        case value, token
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value.description, forKey: .value)
        try container.encode(token, forKey: .token)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        self.value = BigUInt(stringLiteral: value)
        self.token = try container.decode(Token.self, forKey: .token)
    }
}
