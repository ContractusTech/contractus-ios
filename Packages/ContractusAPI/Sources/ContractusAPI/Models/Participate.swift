//
//  Participate.swift
//  
//
//  Created by Simon Hudishkin on 20.09.2022.
//

import Foundation

public enum ParticipateType: String, Codable {
    case contractor = "CONTRACTOR",
         checker = "CHECKER"
}

public struct NewParticipate: Codable {
    let type: ParticipateType
    let publicKey: String
    let blockchain: Blockchain

    public init(type: ParticipateType, publicKey: String, blockchain: Blockchain) {
        self.type = type
        self.publicKey = publicKey
        self.blockchain = blockchain
    }
}

extension Blockchain: Codable { }
