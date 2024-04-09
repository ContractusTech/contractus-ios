import Foundation
import ContractusAPI
import Combine

extension PrepaidViewModel {
    struct State {
        enum Status: Equatable {
            case ready, loading, error(String), success
        }

        enum ErrorState: Equatable {
            case error(String)
        }

        var amount: String = ""
        var status: Status = .ready
    }
    
    enum Input {
        case setAmount(String), save
    }
    

}

final class PrepaidViewModel: ViewModel {

    @Published private(set) var state: State
    private var dealService: ContractusAPI.DealsService?
    private let deal: Deal
    
    init(deal: Deal, dealService: ContractusAPI.DealsService?) {
        self.deal = deal
        self.dealService = dealService
        self.state = .init()
    }
    
    func trigger(_ input: Input, after: AfterTrigger? = nil) {
        switch input {
        case .setAmount(let amount):
            updateAmount(amount: amount)
        case .save:
            guard let amount = AmountFormatter.format(string: state.amount, decimal: deal.token.decimals) else { return }

            state.status = .loading

            Task { @MainActor in
                do {
                    try await updatePrepayment(amount: .init(amount, token: deal.token))
                    state.status = .success
                } catch {
                    state.status = .error(error.localizedDescription)
                }

            }

        }
    }
    
    private func updateAmount(amount: String) {
        var state = state
        let amountDouble = amount.double
        
        state.amount = amount
        self.state = state
    }

    private func updatePrepayment(amount: Amount) async throws {

        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            let data = UpdateDeal(amount: nil, checkerAmount: nil, prepaymentAmount: amount, ownerBondAmount: nil, contractorBondAmount: nil, deadline: nil, allowHolderMode: nil)

            dealService?.update(dealId: deal.id, data: data, completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        })
    }
}
