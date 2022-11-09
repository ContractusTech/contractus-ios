//
//  ChangeAmountViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 28.09.2022.
//

import Foundation
import ContractusAPI
import Combine

enum ChangeAmountInput {
    case changeAmount(String, Currency)
    case update
}

struct ChangeAmountState {

    enum State: Equatable {
        case loading, error(String), success, none
    }
    var state: State = .none
    var dealId: String
    var amount: Amount?
    var isValid: Bool {
        amount != nil && amount?.value != 0
    }
}

final class ChangeAmountViewModel: ViewModel {

    @Published private(set) var state: ChangeAmountState

    private var dealService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(
        state: ChangeAmountState,
        dealService: ContractusAPI.DealsService?)
    {
        self.state = state
        self.dealService = dealService
    }

    func trigger(_ input: ChangeAmountInput, after: AfterTrigger? = nil) {

        switch input {
        case .changeAmount(let amount, let currency):

            if Amount.isValid(amount, currency: currency) {
                self.state.amount = Amount(amount, currency: currency)
            } else {
                self.state.amount = nil
            }

        case .update:
            guard let amount = state.amount else { return }
            self.state.state = .loading
            dealService?.update(dealId: state.dealId, data: UpdateDeal(amount: amount), completion: { result in
                switch result {
                case .success:
                    self.state.state = .success
                case .failure(let error):
                    self.state.state = .error(error.localizedDescription)
                }
            })
        }
    }


}
