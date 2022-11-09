//
//  Account.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.08.2022.
//

import Foundation
import TweetNacl
import Base58Swift
import SolanaSwift
import ContractusAPI

extension SolanaSwift.Account {
    var blockchain: Blockchain { .solana }
}
