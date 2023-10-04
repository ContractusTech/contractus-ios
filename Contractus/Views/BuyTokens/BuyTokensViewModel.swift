//
//  BuyTokensViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 28.09.2023.
//

enum BuyTokensInput {
    case resetError
}

struct BuyTokensState {
    enum ErrorState: Equatable {
        case error(String)
    }
    
    enum State {
        case loading, loaded
    }
    
    var state: State
    var errorState: ErrorState?
}

final class BuyTokensViewModel: ViewModel {

    @Published private(set) var state: BuyTokensState

    init() {
        
        self.state = .init(
            state: .loading
        )
    }
    
    func trigger(_ input: BuyTokensInput, after: AfterTrigger?) {
        switch input {
        case .resetError:
            self.state.errorState = nil
        }
    }
}
