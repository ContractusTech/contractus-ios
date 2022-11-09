//
//  Balance.swift
//  
//
//  Created by Simon Hudishkin on 26.09.2022.
//

import Foundation

public struct Balance: Decodable {

    public let estimateAmount: Double
    public let solAmount: UInt64
    public let usdcAmount: Double
    public let blockchain: String

    public init(estimateAmount: Double, solAmount: UInt64, usdcAmount: Double, blockchain: String) {
        self.estimateAmount = estimateAmount
        self.solAmount = solAmount
        self.usdcAmount = usdcAmount
        self.blockchain = blockchain
    }


}
