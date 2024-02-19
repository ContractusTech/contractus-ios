//
//  WrapTokenViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.02.2023.
//

import Foundation
import ContractusAPI

enum WrapTokenInput {
    case swap, update(String), send(String), hideError
}

struct WrapTokenState {

    enum OperationType {
        case wrap, unwrap
    }

    enum State: Equatable {
        case ready, loading
    }

    enum ErrorState: Equatable {
        case error(String)
    }

    let account: CommonAccount
    let amountNativeToken: Amount
    let amountWrapToken: Amount
    var operationType: OperationType = .wrap
    var transactionSignType: TransactionSignType?
    var errorState: ErrorState?
    var state: Self.State = .ready

    var allowAll: Bool {
        switch operationType {
        case .wrap:
            return !amountNativeToken.value.isZero
        case .unwrap:
            return false
        }
    }

    var from: Amount {
        switch operationType {
        case .wrap:
            return amountNativeToken
        case .unwrap:
            return amountWrapToken
        }
    }

    var to: Amount {
        switch operationType {
        case .wrap:
            return amountWrapToken
        case .unwrap:
            return amountNativeToken
        }
    }

    var disableAction: Bool = true
}

final class WrapTokenViewModel: ViewModel {

    @Published private(set) var state: WrapTokenState
    private var transactionsService: ContractusAPI.TransactionsService?

    init(state: WrapTokenState, transactionsService: ContractusAPI.TransactionsService?) {
        self.state = state
        self.transactionsService = transactionsService
    }

    func trigger(_ input: WrapTokenInput, after: AfterTrigger?) {
        switch input {
        case .update(let amount):
            if let amount = AmountFormatter.format(string: amount, token: state.from.token) {
                state.disableAction = amount.isZero || amount > state.from.value
            } else {
                state.disableAction = true
            }
        case .swap:
            state.operationType = state.operationType == .unwrap ? .wrap : .unwrap
            switch state.operationType {
            case .wrap:
                state.disableAction = true
            case .unwrap:
                state.disableAction = state.amountWrapToken.value.isZero
            }
        case .hideError:
            state.errorState = nil
        case .send(let amount):
            switch state.operationType {
            case .wrap:
                guard let amount = AmountFormatter.format(string: amount, token: state.from.token) else {
                    return
                }
                let operationAmount = AmountValue(amount)
                state.state = .loading
                Task { @MainActor in
                    do {
                        let tx = try await sendWrap(amount: operationAmount)
                        state.transactionSignType = .byTransaction(tx)
                    } catch {
                        state.errorState = .error(error.localizedDescription)
                    }
                    state.state = .ready
                }
            case .unwrap:
                state.state = .loading
                Task { @MainActor in
                    do {
                        let tx = try await sendUnwrap()
                        state.transactionSignType = .byTransaction(tx)
                        after?()
                    } catch {
                        state.errorState = .error(error.localizedDescription)
                    }
                    state.state = .ready
                }

            }

        }
    }

    func sendWrap(amount: AmountValue) async throws -> Transaction {
        try await withCheckedThrowingContinuation({ continuation in
            transactionsService?.wrap(amount, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    func sendUnwrap() async throws -> Transaction {
        try await withCheckedThrowingContinuation({ continuation in
            transactionsService?.unwrapAll(completion: { result in
                continuation.resume(with: result)
            })
        })
    }

}

fileprivate extension ContractusAPI.Blockchain {
    var decimals: Int {
        switch self {
        case .solana:
            return 9
        case .bsc:
            // TODO: - 
            return 0
        }
    }
}
