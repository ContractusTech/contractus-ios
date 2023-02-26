//
//  Balance.swift
//  
//
//  Created by Simon Hudishkin on 26.09.2022.
//

import Foundation
import BigInt

public struct Balance: Decodable {

    public let estimateAmount: Double
    public let blockchain: String
    public let tokens: [Amount]
    public let wrap: [String]

    public init(estimateAmount: Double, tokens: [Amount], blockchain: String, wrap: [String]) {
        self.estimateAmount = estimateAmount
        self.tokens = tokens
        self.blockchain = blockchain
        self.wrap = wrap
    }
}
