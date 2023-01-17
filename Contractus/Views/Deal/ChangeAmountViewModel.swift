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

enum AmountValueType {
    case deal, checker

    var asAmountFeeType: AmountFeeType {
        switch self {
        case .checker: return .checkerAmount
        case .deal: return .dealAmount
        }
    }
}

struct ChangeAmountState {


    enum State: Equatable {
        case loading, changingAmount, error(String), success, none
    }
    var state: State = .none
    var deal: Deal
    let amountType: AmountValueType
    var amount: Amount
    var feeAmount: Amount
    var fee: Double = 0
    var feeFormatted: String = ""
    let account: CommonAccount

    var totalAmount: Amount {
        switch amountType {
        case .deal:
            return Amount(amount.value + (deal.checkerAmount ?? 0) + feeAmount.value, currency: amount.currency)
        case .checker:
            return Amount(amount.value + deal.amount + feeAmount.value, currency: amount.currency)
        }
    }

    var dealAmount: Amount {
        if amountType == .deal {
            return amount
        }
        return Amount(deal.amount, currency: amount.currency)
    }

    var checkerAmount: Amount {
        if amountType == .checker {
            return amount
        }
        return Amount(deal.checkerAmount ?? 0, currency: amount.currency)
    }

    var isValid: Bool {
        amount.value != 0
    }

    var allowChangeCurrency: Bool {
        amountType != .checker
    }

    var checkerIsYou: Bool {
        account.publicKey == deal.checkerPublicKey || deal.checkerPublicKey == nil
    }
}

final class ChangeAmountViewModel: ViewModel {

    @Published private(set) var state: ChangeAmountState

    private var dealService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(deal: Deal, account: CommonAccount, amountType: AmountValueType, dealService: ContractusAPI.DealsService?)
    {
        self.state = .init(
            deal: deal,
            amountType: amountType,
            amount: amountType == .deal ? Amount(deal.amount, currency: deal.currency) : Amount(deal.checkerAmount ?? 0, currency: deal.currency),
            feeAmount: Amount(deal.amountFee, currency: deal.currency),
            account: account
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
            let data: UpdateAmountDeal
            switch state.amountType {
            case .deal:
                data = UpdateAmountDeal(amount: state.amount, checkerAmount: nil)
            case .checker:
                data = UpdateAmountDeal(amount: nil, checkerAmount: state.amount)
            }
            dealService?.update(dealId: state.deal.id, data: data, completion: { [weak self] result in
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
        dealService?.getFee(dealId: state.deal.id, data: CalculateDealFee(amount: amount, type: state.amountType.asAmountFeeType), completion: {[weak self] result in
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
