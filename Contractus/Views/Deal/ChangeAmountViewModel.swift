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
        case loading, changingAmount, error(String), success, none
    }
    var state: State = .none
    var dealId: String
    var amount: Amount
    var feeAmount: Amount
    var fee: Double = 0
    var feeFormatted: String = ""

    var totalAmount: Amount {
        return Amount(amount.value + feeAmount.value, currency: amount.currency)
    }

    var isValid: Bool {
        amount.value != 0
    }
}

final class ChangeAmountViewModel: ViewModel {

    @Published private(set) var state: ChangeAmountState

    private var dealService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(dealId: String, amount: Amount, feeAmount: Amount, dealService: ContractusAPI.DealsService?)
    {
        self.state = .init(
            dealId: dealId,
            amount: amount,
            feeAmount: feeAmount
        )
        self.dealService = dealService
    }

    func trigger(_ input: ChangeAmountInput, after: AfterTrigger? = nil) {

        switch input {
        case .changeAmount(let amount, let currency):
            var amount = amount
            if amount.isEmpty {
                amount = "0"
            }
            if Amount.isValid(amount, currency: currency) {
                let newAmount = Amount(amount, currency: currency)
                self.state.amount = newAmount
                updateFee(amount: newAmount)
            } else {
                self.state.amount = Amount(self.state.amount.value, currency: self.state.amount.currency)
            }

        case .update:
            self.state.state = .changingAmount
            dealService?.update(dealId: state.dealId, data: UpdateAmountDeal(amount: state.amount, feeAmount: state.feeAmount), completion: { [weak self] result in
                switch result {
                case .success:
                    self?.state.state = .success
                case .failure(let error):
                    self?.state.state = .error(error.localizedDescription)
                }
            })
        }
    }

    private func updateFee(amount: Amount) {
        self.state.state = .loading
        dealService?.getFee(dealId: state.dealId, data: CalculateDealFee(amount: amount), completion: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fee):
                var newState = self.state
                newState.fee = fee.fee
                newState.feeAmount = fee.feeAmount
                newState.feeFormatted = fee.fee.format(for: self.state.amount.currency)
                newState.state = .none
                self.state = newState
            case .failure(let error):
                debugPrint(error.localizedDescription)
                self.state.state = .error(error.localizedDescription)
            }

        })
    }


}
