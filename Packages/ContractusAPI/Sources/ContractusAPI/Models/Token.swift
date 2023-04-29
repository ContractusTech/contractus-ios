//
//  Token.swift
//  
//
//  Created by Simon Hudishkin on 31.01.2023.
//

import Foundation
import BigInt

public struct Token: Codable {

    public let code: String
    public let name: String?
    public let address: String?
    public let native: Bool
    public let decimals: Int

    enum CodingKeys: CodingKey {
        case code
        case name
        case address
        case native
        case decimals
    }

    public init(code: String, name: String? = nil, address: String? = nil, native: Bool, decimals: Int) {
        self.code = code
        self.name = name
        self.address = address
        self.native = native
        self.decimals = decimals
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Token.CodingKeys> = try decoder.container(keyedBy: Token.CodingKeys.self)

        self.code = try container.decode(String.self, forKey: Token.CodingKeys.code)
        self.name = try? container.decodeIfPresent(String.self, forKey: Token.CodingKeys.name)
        self.address = try container.decodeIfPresent(String.self, forKey: Token.CodingKeys.address)
        self.native = try container.decode(Bool.self, forKey: Token.CodingKeys.native)
        self.decimals = try container.decode(Int.self, forKey: Token.CodingKeys.decimals)

    }

    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<Token.CodingKeys> = encoder.container(keyedBy: Token.CodingKeys.self)

        try container.encode(self.code, forKey: Token.CodingKeys.code)
        try container.encodeIfPresent(self.name, forKey: Token.CodingKeys.name)
        try container.encodeIfPresent(self.address, forKey: Token.CodingKeys.address)
        try container.encode(self.native, forKey: Token.CodingKeys.native)
        try container.encode(self.decimals, forKey: Token.CodingKeys.decimals)
    }
}

public extension Token {

    func format(amount: BigUInt, withCode: Bool = false) -> String {
        AmountFormatter.format(amount: amount, token: self, withCode: withCode)
    }

    func format(string: String, withCode: Bool = false) -> BigUInt? {
        AmountFormatter.format(string: string, token: self, withCode: withCode)
    }
//
//    static func from(code: String, blockchain: Blockchain = .solana) -> Token {
//        switch blockchain {
//        case .solana:
//            if let token = SolanaTokens.list.first(where: {$0.code == code}){
//                return token
//            }
//            return SolanaTokens.unknown
//        }
//    }
//
//    static func from(address: String, blockchain: Blockchain = .solana) -> Token {
//        switch blockchain {
//        case .solana:
//            if let token = SolanaTokens.list.first(where: {$0.address == address}){
//                return token
//            }
//            return SolanaTokens.unknown
//        }
//    }
}

extension Token: Equatable, Hashable { }
