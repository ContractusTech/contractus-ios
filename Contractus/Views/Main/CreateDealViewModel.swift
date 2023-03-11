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
    case createDealAsClient,
         createDealAsExecutor,
         copy,
         hideError
}

struct CreateDealState {

    enum State {
        case none, creating, success, error
    }
    var account: CommonAccount
    var state: State = .none
    var createdDeal: Deal?
    var errorMessage: String = ""
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
        case .createDealAsClient:
            create(for: .client)
        case .createDealAsExecutor:
            create(for: .executor)
        case .copy:
            if let share = state.shareable?.shareContent {
                UIPasteboard.general.string = share
            }
        case .hideError:
            self.state.state = .none
        }
    }

    // MARK: - Private Methods

    private func create(for role: OwnerRole) {

        Task { @MainActor in
            guard let secret = try? await SharedSecretService.createSharedSecret(privateKey:state.account.privateKey) else {
                return
            }
            self.state.state = .creating
            let newDeal = NewDeal(
                role: role,
                encryptedSecretKey: secret.base64EncodedSecret,
                secretKeyHash: secret.hashOriginalKey,
                sharedKey: secret.serverSecret.base64EncodedString())

            guard let deal = try? await self.createDeal(deal: newDeal) else {
                self.state.state = .error
                return
            }
            var newState = self.state
            newState.shareable = ShareableDeal(dealId: deal.id, secretBase64: secret.clientSecret.base64EncodedString())
            newState.state = .success
            newState.createdDeal = deal
            self.state = newState
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
