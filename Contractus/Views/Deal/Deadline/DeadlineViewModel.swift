//
//  DeadlineViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 24.05.2023.
//
import Foundation
import ContractusAPI

final class DeadlineViewModel: ViewModel {

    enum Input {
        case updateDeadline(Date)
        case hideError
    }

    struct State {
        enum State {
            case none, loading, success
        }

        enum ErrorState: Equatable {
            case error(String)
        }
        var deal: Deal
        let account: CommonAccount
        var state: Self.State = .none
        var errorState: ErrorState?
    }

    @Published private(set) var state: State

    private var dealService: ContractusAPI.DealsService?

    init(deal: Deal, account: CommonAccount, dealService: ContractusAPI.DealsService?)
    {
        self.state = .init(
            deal: deal,
            account: account
        )
        self.dealService = dealService
    }

    func trigger(_ input: Input, after: AfterTrigger? = nil) {

        switch input {
        case .hideError:
            state.errorState = .none
        case .updateDeadline(let value):
            state.state = .loading
            Task { @MainActor in
                do {
                    let newDeal = try await update(deadline:value)
                    state.state = .success
                    state.deal = newDeal
                } catch {
                    state.state = .none
                    state.errorState = .error(error.localizedDescription)
                }

            }
        }
    }

    private func update(deadline: Date) async throws -> Deal {
        try await withCheckedThrowingContinuation { continuation in
            dealService?.update(dealId: state.deal.id, data: UpdateDeal(amount: nil, checkerAmount: nil, ownerBondAmount: nil, contractorBondAmount: nil, deadline: deadline, allowHolderMode: nil), completion: { result in
                continuation.resume(with: result)
            })
        }

    }


}
