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

    public init(publicKey: String, blockchain: String, createdAt: String) {
        self.publicKey = publicKey
        self.blockchain = blockchain
        self.createdAt = createdAt
    }

}
