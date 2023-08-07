//
//  CreateDealViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 27.09.2022.
//

import Foundation
import ContractusAPI
import Combine
import SolanaSwift
import UIKit

enum CreateDealInput {
    case createDealWithChecker(OwnerRole, Bool),
         createDeal(OwnerRole, PerformanceBondType, Bool),
         copy,
         hideError
}

struct CreateDealState {
    enum State: Equatable {
        case none, creating, success, error(String)
    }
    var account: CommonAccount
    var state: State = .none
    var createdDeal: Deal?
    var shareable: Shareable?
}

final class CreateDealViewModel: ViewModel {

    @Published private(set) var state: CreateDealState

    private var dealsAPIService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()

    init(
        account: CommonAccount,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?)
    {
        self.state = CreateDealState(account: account)
        self.dealsAPIService = dealsAPIService
    }

    func trigger(_ input: CreateDealInput, after: AfterTrigger? = nil) {
        switch input {
        case .createDealWithChecker(let role, let encrypt):
            create(for: role, witchChecker: true, bondType: .none, encrypt: encrypt)
        case .createDeal(let role, let bondType, let encrypt):
            create(for: role, witchChecker: false, bondType: bondType, encrypt: encrypt)
        case .copy:
            if let share = state.shareable?.shareContent {
                UIPasteboard.general.string = share
            }
        case .hideError:
            self.state.state = .none
        }
    }

    // MARK: - Private Methods

    private func create(for role: OwnerRole, witchChecker: Bool, bondType: PerformanceBondType, encrypt: Bool) {

        Task { @MainActor in
            guard let secret = try? await SharedSecretService.createSharedSecret(privateKey: state.account.privateKey) else {
                return
            }
            self.state.state = .creating
            let newDeal = encrypt
            ? NewDeal(
                role: role,
                encryptedSecretKey: secret.base64EncodedSecret,
                secretKeyHash: secret.hashOriginalKey,
                sharedKey: secret.serverSecret.base64EncodedString(),
                performanceBondType: bondType,
                completionCheckType: witchChecker ? .checker : .none
            )
            : NewDeal(
                role: role,
                performanceBondType: bondType,
                completionCheckType: witchChecker ? .checker : .none
            )

            do {
                let deal = try await self.createDeal(deal: newDeal)
                var newState = self.state
                if encrypt {
                    newState.shareable = ShareableDeal(dealId: deal.id, secretBase64: secret.clientSecret.base64EncodedString())
                }
                newState.state = .success
                newState.createdDeal = deal
                self.state = newState
            } catch {
                self.state.state = .error(error.readableDescription)
            }
        }
    }

    private func createDeal(deal: NewDeal) async throws -> Deal {
        try await withCheckedThrowingContinuation { promise in
            self.dealsAPIService?.create(
                data: deal, completion: { result in
                    promise.resume(with: result)
            })
        }
    }
}
