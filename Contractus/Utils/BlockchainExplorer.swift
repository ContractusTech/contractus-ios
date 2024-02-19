//
//  BlockchainExplorer.swift
//  Contractus
//
//  Created by Simon Hudishkin on 12.05.2023.
//

import SwiftUI
import ContractusAPI

enum BlockchainExplorer {

    static func openExplorer(blockchain: Blockchain, txSignature: String) {
        switch blockchain {
        case .solana:
            UIApplication.shared.open(URL.solscanURL(signature: txSignature, isDevnet: AppConfig.serverType.isDevelop))
        case .bsc:
            UIApplication.shared.open(URL.bscURL(signature: txSignature, isDevnet: AppConfig.serverType.isDevelop))
        }

    }
}
