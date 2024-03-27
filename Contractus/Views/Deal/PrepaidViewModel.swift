import Foundation
import ContractusAPI
import Combine

extension PrepaidViewModel {
    struct State {
        enum State: Equatable {
            case ready, loading
        }

        enum ErrorState: Equatable {
            case error(String)
        }

        var amount: String = ""
    }
    
    enum Input {
        case setAmount(String), save
    }
    

}

final class PrepaidViewModel: ViewModel {
    @Published private(set) var state: State

    init(
        state: PrepaidViewModel.State
    ) {
        self.state = state
    }
    
    func trigger(_ input: Input, after: AfterTrigger? = nil) {
        switch input {
        case .setAmount(let amount):
            updateAmount(amount: amount)
        case .save:
            return
        }
    }
    
    private func updateAmount(amount: String) {
        var state = state
        let amountDouble = amount.double
        
        state.amount = amount
        self.state = state
    }
}
