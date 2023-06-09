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
    case changeAmount(String, Token)
    case changeToken(Token)
    case changeholderMode(Bool)
    case update
}

enum AmountValueType {
    case deal, checker, ownerBond, contractorBond

    var asAmountFeeType: AmountFeeType? {
        switch self {
        case .checker: return .checkerAmount
        case .deal: return .dealAmount
        case .ownerBond, .contractorBond:
            return nil
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
    var tier: Balance.Tier
    var feeAmount: Amount
    var feePercent: Double = 0
    var feeFormatted: String = ""
    var fiatFeeFormatted: String = ""
    let account: CommonAccount
    var allowHolderMode: Bool

    var totalAmount: Amount {
        switch amountType {
        case .deal:
            return Amount(amount.value + (deal.checkerAmount ?? 0) + feeAmount.value, token: amount.token)
        case .checker:
            return Amount(amount.value + deal.amount + feeAmount.value, token: amount.token)
        case .ownerBond, .contractorBond:
            return Amount(amount.value, token: amount.token)
        }
    }

    var dealAmount: Amount {
        if amountType == .deal {
            return amount
        }
        return Amount(deal.amount, token: amount.token)
    }

    var checkerAmount: Amount {
        if amountType == .checker {
            return amount
        }
        return Amount(deal.checkerAmount ?? 0, token: amount.token)
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

    var clientIsYou: Bool {
        account.publicKey == deal.ownerPublicKey && deal.ownerRole == .client ||
        account.publicKey == deal.contractorPublicKey && deal.ownerRole == .executor
    }

    var contractorIsClient: Bool {
        account.publicKey == deal.contractorPublicKey && deal.ownerRole == .executor
    }

    var ownerIsClient: Bool {
        account.publicKey == deal.ownerPublicKey && deal.ownerRole == .client
    }
}

final class ChangeAmountViewModel: ViewModel {

    @Published private(set) var state: ChangeAmountState

    private var dealService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(deal: Deal, account: CommonAccount, amountType: AmountValueType, dealService: ContractusAPI.DealsService?, tier: Balance.Tier)
    {
        self.state = .init(
            deal: deal,
            amountType: amountType,
            amount: amountType == .deal ? Amount(deal.amount, token: deal.token) : Amount(deal.checkerAmount ?? 0, token: deal.token),
            tier: tier,
            feeAmount: Amount(deal.amountFee, token: deal.token),
            account: account,
            allowHolderMode: false
        )
        self.dealService = dealService
    }

    func trigger(_ input: ChangeAmountInput, after: AfterTrigger? = nil) {

        switch input {
        case .changeAmount(let amount, let token):
            var amount = amount
            if amount.isEmpty {
                amount = "0"
            }
            if Amount.isValid(amount, token: token) {
                let newAmount = Amount(amount, token: token)
                self.state.amount = newAmount
                updateFee(amount: newAmount)
            } else {
                self.state.amount = Amount(self.state.amount.value, token: self.state.amount.token)
            }
        case .changeToken(let token):
            let amount = self.state.amount.value
            let newAmount = Amount(amount, token: token)
            self.state.amount = newAmount
            updateFee(amount: newAmount)
        case .changeholderMode(let holderMode):
            self.state.allowHolderMode = holderMode
            let amount = self.state.amount
            updateFee(amount: amount)
        case .update:
            self.state.state = .changingAmount
            let data: UpdateDeal
            switch state.amountType {
            case .deal:
                data = UpdateDeal(amount: state.amount, checkerAmount: nil, ownerBondAmount: nil, contractorBondAmount: nil, deadline: nil, allowHolderMode: state.allowHolderMode)
            case .checker:
                data = UpdateDeal(amount: nil, checkerAmount: state.amount, ownerBondAmount: nil, contractorBondAmount: nil, deadline: nil, allowHolderMode: state.allowHolderMode)
            case .contractorBond:
                data = UpdateDeal(amount: nil, checkerAmount: nil, ownerBondAmount: nil, contractorBondAmount: state.amount, deadline: nil, allowHolderMode: state.allowHolderMode)
            case .ownerBond:
                data = UpdateDeal(amount: nil, checkerAmount: nil, ownerBondAmount: state.amount, contractorBondAmount: nil, deadline: nil, allowHolderMode: state.allowHolderMode)
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
        guard let feeType = state.amountType.asAmountFeeType else { return }

        if amount.value.isZero {
            var newState = self.state
            newState.feePercent = 0
            newState.feeAmount = Amount(UInt64(0), token: amount.token)
            newState.feeFormatted = "(0%) \(Amount(UInt64(0), token: amount.token).formatted(withCode: true))"
            newState.fiatFeeFormatted = "-" //fee.fiatCurrency.format(double: 0, withCode: true) ?? ""
            newState.state = .none
            self.state = newState
            return
        }
        self.state.state = .loading
        let holderMode = self.state.allowHolderMode
        dealService?.getFee(dealId: state.deal.id, data: CalculateDealFee(amount: amount, type: feeType, allowHolderMode: holderMode), completion: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fee):
                var newState = self.state
                newState.feePercent = fee.percent
                newState.feeAmount = fee.feeAmount
                newState.feeFormatted = "(\(fee.percent.formatAsPercent())%) \(fee.feeAmount.formatted(withCode: true))"
                newState.fiatFeeFormatted = fee.fiatCurrency.format(double: fee.fiatFee, withCode: true) ?? ""
                newState.state = .none
                self.state = newState
            case .failure(let error):
                debugPrint(error.localizedDescription)
                self.state.state = .error(error.localizedDescription)
            }

        })
    }


}
