//
//  TransactionSignViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 04.01.2023.
//

import Foundation
import ContractusAPI

enum TransactionSignType: Equatable, Identifiable {
    var id: String { "\(self)" }
    case byDeal(Deal)
    case byTransactionId(String)
    case byTransaction(Transaction)
}

enum TransactionSignError: Error {
    case transactionIsNull
}

enum TransactionSignInput {
    case sign
    case hideError
}

struct TransactionSignState {

    enum ErrorState: Equatable {
        case error(String)
    }
    enum State {
        case loading, loaded, signing, signed
    }

    struct InformationItem: Identifiable {
        var id: String {
            return "\(self)"
        }

        let title: String
        let value: String

        let titleDescription: String?
        let valueDescription: String?

    }

    let account: CommonAccount
    var state: State
    var errorState: ErrorState?
    var type: TransactionSignType
    var transaction: Transaction?
    var informationFields: [InformationItem]
    var allowSign: Bool = false
    var isOwnerDeal: Bool {

        switch type {
        case .byDeal(let deal):
            return deal.ownerPublicKey == account.publicKey
        case .byTransactionId:
            return transaction?.initializerPublicKey == account.publicKey
        case .byTransaction(let tx):
            return tx.initializerPublicKey == account.publicKey
        }

    }
}

final class TransactionSignViewModel: ViewModel {

    @Published private(set) var state: TransactionSignState

    private var dealService: ContractusAPI.DealsService?
    private var accountService: ContractusAPI.AccountService?
    private var transactionSignService: TransactionSignService?

    init(
        account: CommonAccount,
        type: TransactionSignType,
        dealService: ContractusAPI.DealsService? = nil,
        accountService: ContractusAPI.AccountService? = nil,
        transactionSignService: TransactionSignService? = nil
    ) {

        self.dealService = dealService
        self.transactionSignService = transactionSignService
        self.accountService = accountService

        switch type {
        case .byDeal(let deal):

            self.state = .init(
                account: account,
                state: .loading,
                type: type,
                informationFields: Self.fieldsByDeal(deal, account: account))

            Task { @MainActor in
                do {
                    let tx = try await getActualTx()
                    var newState = self.state
                    newState.transaction = tx
                    newState.state = .loaded
                    newState.allowSign = true
                    if let tx = tx, let fee = tx.fee {
                        newState.informationFields.append(.init(title: "Service Fee", value: deal.token.format(amount: fee, withCode: true), titleDescription: nil, valueDescription: nil))
                    }

                    self.state = newState
                } catch {
                    var newState = self.state
                    newState.errorState = .error(error.localizedDescription)
                    newState.state = .loaded
                    newState.allowSign = false
                    self.state = newState
                }
            }
        case .byTransactionId(let id):
            fatalError("No implementation .byTransactionId(let id)")
        case .byTransaction(let tx):
            self.state = .init(account: account, state: .loaded, type: type, transaction: tx, informationFields: Self.fieldsForTx(tx, account: account))
            self.state.allowSign = true
        }
    }

    func trigger(_ input: TransactionSignInput, after: AfterTrigger?) {
        switch input {
        case .hideError:
            state.errorState = nil
        case .sign:
            self.state.state = .signing
            Task { @MainActor in
                do {
                    _ = try await sign()
                    var newState = self.state
                    newState.errorState = nil
                    newState.state = .signed
                    self.state = newState
                } catch {
                    var newState = self.state
                    newState.state = .loaded
                    newState.errorState = .error(error.localizedDescription)
                    self.state = newState
                }
            }
        }
    }

    private func getActualTx() async throws -> Transaction? {
        guard case .byDeal(let deal) = state.type else { return nil }
        return try await withCheckedThrowingContinuation({ continuation in
            dealService?.getActualTransaction(dealId: deal.id, silent: false, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    private func sign() async throws -> Transaction? {
        switch state.type {
        case .byDeal(let deal):
            return try await withCheckedThrowingContinuation({ continuation in
                guard let transaction = state.transaction else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }
                guard let (signature, message) = try? transactionSignService?.sign(txBase64: transaction.transaction, by: self.state.account.privateKey) else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }

                dealService?.signTransaction(dealId: deal.id, type: transaction.type, data: .init(transaction: message, signature: signature), completion: { result in
                    continuation.resume(with: result)
                })
            })
        case .byTransaction(let tx):
            return try await withCheckedThrowingContinuation({ continuation in
                guard let (signature, message) = try? transactionSignService?.sign(txBase64: tx.transaction, by: self.state.account.privateKey) else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }
                switch tx.type {
                case .wrapSOL:
                    accountService?.signWrap(.init(id: tx.id, transaction: message, signature: signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .unwrapAllSOL:
                    accountService?.signUnwrapAll(.init(id: tx.id, transaction: message, signature: signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .dealFinish, .dealInit, .dealCancel:
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                }


            })
        case .byTransactionId(_):
            fatalError("No implementation")
        }
    }

    static private func fieldsByDeal(_ deal: Deal, account: CommonAccount) -> [TransactionSignState.InformationItem] {
        var fields: [TransactionSignState.InformationItem] = [
            .init(title: "Type", value: "Confirm Deal", titleDescription: nil, valueDescription: nil),
            .init(title: "Amount", value: deal.token.format(amount: deal.amount, withCode: true), titleDescription: nil, valueDescription: nil),
        ]

        if deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey {
            fields.insert(.init(title: "Executor", value: ContentMask.mask(from: deal.ownerPublicKey), titleDescription: nil, valueDescription: nil), at: 0)
        } else {
            if let contractorPublicKey = deal.contractorPublicKey {
                fields.insert(.init(title: "Executor", value:  ContentMask.mask(from: contractorPublicKey), titleDescription: nil, valueDescription: nil), at: 0)
            }
        }
        if let checkerAmount = deal.checkerAmount {
            fields.append(.init(title: "Verifier Fee", value: deal.token.format(amount: checkerAmount, withCode: true), titleDescription: nil, valueDescription: nil))
        }

        return fields
    }

    static private func fieldsForTx(_ tx: Transaction, account: CommonAccount) -> [TransactionSignState.InformationItem] {
        var fields: [TransactionSignState.InformationItem] = [
            .init(title: "Type", value: tx.type.title, titleDescription: nil, valueDescription: nil),
        ]

        if tx.type == .wrapSOL {
            fields.append(.init(title: "Amount", value: tx.amountFormatted ?? "", titleDescription: nil, valueDescription: nil))
        }

        if let fee = tx.feeFormatted {
            fields.append(.init(title: "Fee", value: fee, titleDescription: nil, valueDescription: nil))
        } else {
            fields.append(.init(title: "Fee", value: "Free", titleDescription: nil, valueDescription: nil))
        }
        
        return fields
    }
}

private extension ContractusAPI.TransactionType {
    var title: String {
        switch self {
        case .wrapSOL: return "Wrap SOL"
        case .dealInit: return "Confirm Deal"
        case .dealCancel: return "Cancel Deal"
        case .dealFinish: return "Finish Deal"
        case .unwrapAllSOL: return "Unwrap Token"
        }
    }
}
