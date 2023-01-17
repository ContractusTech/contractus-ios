//
//  SignConfirmViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 04.01.2023.
//

import Foundation
import ContractusAPI

enum SignConfirmError: Error {
    case transactionIsNull
}

enum SignConfirmInput {
    case loadActualTx
    case sign
    case hideError
}

struct SignConfirmState {

    enum ErrorState {
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
    }

    let account: CommonAccount
    var state: State
    var errorState: ErrorState?
    var deal: Deal
    var transaction: DealTransaction?
    let informationFields: [InformationItem]

    var isOwnerDeal: Bool {
        deal.ownerPublicKey == account.publicKey
    }
}

final class SignConfirmViewModel: ViewModel {

    @Published private(set) var state: SignConfirmState

    private var dealService: ContractusAPI.DealsService?
    private var transactionSignService: TransactionSignService?

    init(
        account: CommonAccount,
        deal: Deal,
        dealService: ContractusAPI.DealsService? = nil,
        transactionSignService: TransactionSignService? = nil
    ) {


        var fields: [SignConfirmState.InformationItem] = [

            .init(title: "Amount", value: deal.currency.format(amount: deal.amount, withCode: true)),
            .init(title: "Fee", value: deal.currency.format(amount: deal.amountFee, withCode: true)),
        ]
        if deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey {
            fields.insert(.init(title: "Executor", value: ContentMask.mask(from: deal.ownerPublicKey)), at: 0)
        } else {
            if let contractorPublicKey = deal.contractorPublicKey {
                fields.insert(.init(title: "Executor", value:  ContentMask.mask(from: contractorPublicKey)), at: 0)
            }
        }
        if let checkerAmount = deal.checkerAmount {
            fields.append(.init(title: "Verifier Fee", value: deal.currency.format(amount: checkerAmount, withCode: true)))
        }
        
        self.state = .init(account: account, state: .loading, deal: deal, informationFields: fields)
        self.dealService = dealService
        self.transactionSignService = transactionSignService
    }

    func trigger(_ input: SignConfirmInput, after: AfterTrigger?) {
        switch input {
        case .hideError:
            state.errorState = nil
        case .loadActualTx:

            Task {
                guard let tx = try? await getActualTx() else { return }
                await MainActor.run { [weak self] in
                    self?.state.transaction = tx
                    self?.state.state = .loaded
                }
            }
        case .sign:
            self.state.state = .signing
            Task {
                do {
                    let signedTx = try await sign()
                    await MainActor.run { [weak self] in
                        self?.state.errorState = nil
                        self?.state.state = .signed
                    }
                } catch {
                    await MainActor.run(body: { [weak self] in
                        self?.state.errorState = .error(error.localizedDescription)
                    })
                }
            }
        }
    }

    private func getActualTx() async throws -> DealTransaction? {
        try await withCheckedThrowingContinuation({ continuation in
            dealService?.getActualTransaction(dealId: state.deal.id, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    private func sign() async throws -> DealTransaction? {

        try await withCheckedThrowingContinuation({ continuation in
            guard let transaction = state.transaction else {
                continuation.resume(throwing: SignConfirmError.transactionIsNull)
                return
            }
            guard let (signature, message) = try? transactionSignService?.signIfNeeded(txBase64: transaction.transaction, by: self.state.account.privateKey) else {
                continuation.resume(throwing: SignConfirmError.transactionIsNull)
                return
            }

            dealService?.signTransaction(dealId: state.deal.id, type: transaction.type, data: .init(transaction: message, signature: signature), completion: { result in
                continuation.resume(with: result)
            })
        })
    }
}
