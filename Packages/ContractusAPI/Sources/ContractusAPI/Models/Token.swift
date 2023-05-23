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
    public let serviced: Bool

    enum CodingKeys: CodingKey {
        case code
        case name
        case address
        case native
        case decimals
        case serviced
    }

    private enum RequestCodingKeys: CodingKey {
        case code
        case address
    }

    public init(code: String, name: String? = nil, address: String? = nil, native: Bool, decimals: Int, serviced: Bool) {
        self.code = code
        self.name = name
        self.address = address
        self.native = native
        self.decimals = decimals
        self.serviced = serviced
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Token.CodingKeys.self)

        self.code = try container.decode(String.self, forKey: Token.CodingKeys.code)
        self.name = try? container.decodeIfPresent(String.self, forKey: Token.CodingKeys.name)
        self.address = try container.decodeIfPresent(String.self, forKey: Token.CodingKeys.address)
        self.native = try container.decode(Bool.self, forKey: Token.CodingKeys.native)
        self.decimals = try container.decode(Int.self, forKey: Token.CodingKeys.decimals)
        self.serviced = (try? container.decode(Bool.self, forKey: Token.CodingKeys.serviced)) ?? false

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Token.RequestCodingKeys.self)

        try container.encode(self.code, forKey: Token.RequestCodingKeys.code)
        try container.encodeIfPresent(self.address, forKey: Token.RequestCodingKeys.address)
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
