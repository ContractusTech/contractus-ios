//
//  TopUpViewModel.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 22.08.2023.
//

import Foundation
import ContractusAPI

final class TopUpViewModel: ViewModel {

    struct State: Equatable {
        enum State: Equatable {
            case none, loadingMethods, loaded(URL)
        }

        enum ErrorState: Equatable {
            case error(String)
        }

        var state: State
        var errorState: ErrorState?
        var disabled: Bool {
            switch state {
            case .loadingMethods:
                return true
            default: return false
            }
        }
    }

    enum Inputs {
        case getMethods,
             hideError
    }

    @Published private(set) var state: State

    private var accountService: ContractusAPI.AccountService?

    init(accountService: ContractusAPI.AccountService?) {
        self.accountService = accountService
        self.state = .init(state: .none)
    }

    func trigger(_ input: Inputs, after: AfterTrigger?) {
        switch input {
        case .getMethods:
            state.state = .loadingMethods
            accountService?.getTopUpMethods {[weak self] result in
                switch result {
                case .success(let data):
                    if let method = data.methods.first, let url = URL(string: method.url ?? "") {
                        self?.state.state = .loaded(url)
                    } else {
                        self?.state.state = .none
                        self?.state.errorState = .error(R.string.localizable.commonServiceUnavailable())
                    }

                case .failure(let error):
                    self?.state.state = .none
                    self?.state.errorState = .error(error.localizedDescription)
                }
            }
        case .hideError:
            state.errorState = nil
        }
    }
}
