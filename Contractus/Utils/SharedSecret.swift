//
//  SharedSecret.swift
//  Contractus
//
//  Created by Simon Hudishkin on 16.09.2022.
//

import ShamirSecretSharing

enum SSS {

    static func createShares(data: [UInt8], n: Int = 2, k: Int = 2) throws -> [[UInt8]] {
        try CreateShares(data: data, n: n, k: k)
    }

    static func combineShares(data: [[UInt8]]) throws -> [UInt8]? {
        try CombineShares(shares: data)
    }
}
