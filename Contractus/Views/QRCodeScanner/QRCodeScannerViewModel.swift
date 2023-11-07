//
//  QRCodeScannerViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 26.11.2022.
//

import Foundation
import ContractusAPI

enum QRCodeScannerInput {
    case parse(String)
    case clear
}

struct QRCodeScannerState {
    enum State: Equatable {
        case none, invalidData, valid(ScanResult)
    }

    var state: State = .none
    let blockchain: Blockchain

}

enum ScanResult: Equatable {
    case publicKey(String), deal(ShareableDeal)
}

final class QRCodeScannerViewModel: ViewModel {

    @Published private(set) var state: QRCodeScannerState

    private let secretStorage: SharedSecretStorage

    init(state: QRCodeScannerState, secretStorage: SharedSecretStorage) {
        self.state = state
        self.secretStorage = secretStorage

    }

    func trigger(_ input: QRCodeScannerInput, after: AfterTrigger?) {
        switch input {
        case .clear:
            state.state = .none
        case .parse(let string):
            guard !string.isEmpty else {
                state.state = .none
                return
            }
            if let dealData = try? ShareableDeal(shareContent: string) {
                state.state = .valid(.deal(dealData))
            } else if state.blockchain.isValidPublicKey(string: string) {
                state.state = .valid(.publicKey(string))
            } else {
                state.state = .invalidData
            }

        }
    }
}

