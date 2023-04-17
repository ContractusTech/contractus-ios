//
//  AccountValidator.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.09.2022.
//

import Foundation
import ContractusAPI
import Base58Swift

enum AccountValidator {
    static func isValidPublicKey(string: String, blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .solana:
            return checkSolanaPublicKey(string)
        }
    }

    private static func checkSolanaPublicKey(_ string: String) -> Bool {
        return Base58.base58Decode(string)?.count == 32
    }
}
