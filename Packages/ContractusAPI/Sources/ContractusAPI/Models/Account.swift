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
    public let isPublic: Bool
    public let displayName: String?
    public let description: String?
    public let encryptedSecretKey: String?

    public init(publicKey: String, blockchain: String, createdAt: String, isPublic: Bool, displayName: String? = nil, description: String? = nil, encryptedSecretKey: String? = nil) {
        self.publicKey = publicKey
        self.blockchain = blockchain
        self.createdAt = createdAt
        self.isPublic = isPublic
        self.displayName = displayName
        self.description = description
        self.encryptedSecretKey = encryptedSecretKey
    }
}
