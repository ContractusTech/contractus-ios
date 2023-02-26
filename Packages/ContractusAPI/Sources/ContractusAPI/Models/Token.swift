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
    public let name: String
    public let address: String?
    public let native: Bool
    public let decimal: Int
}

public extension Token {

    func format(amount: BigUInt, withCode: Bool = false) -> String {
        AmountFormatter.format(amount: amount, token: self, withCode: withCode)
    }

    func format(string: String, withCode: Bool = false) -> BigUInt? {
        AmountFormatter.format(string: string, token: self, withCode: withCode)
    }

    static func from(code: String, blockchain: Blockchain = .solana) -> Token {
        switch blockchain {
        case .solana:
            if let token = SolanaTokens.list.first(where: {$0.code == code}){
                return token
            }
            return SolanaTokens.unknown
        }
    }

    static func from(address: String, blockchain: Blockchain = .solana) -> Token {
        switch blockchain {
        case .solana:
            if let token = SolanaTokens.list.first(where: {$0.address == address}){
                return token
            }
            return SolanaTokens.unknown
        }
    }
}

extension Token: Equatable, Hashable { }
