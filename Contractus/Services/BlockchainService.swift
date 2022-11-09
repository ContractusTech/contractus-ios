//
//  BlockchainService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import Foundation
import ContractusAPI

protocol BlockchainService {
    func getBalances(publicKey: String, estimateCurrency: Currency) async -> Balance
}


