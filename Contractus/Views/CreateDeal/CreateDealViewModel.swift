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
    case setRole(OwnerRole),
         setContractor(String),
         setCheckType(CompletionCheckType),
         setChecker(String),
         setDeadline(Date),
         setBondType(PerformanceBondType),
         setEncryption(Bool),
         createDeal,
         copy,
         hideError,
         close
}

struct CreateDealState {
    enum State: Equatable {
        case none, creating, success, error(String), close
    }
    var account: CommonAccount
    var state: State = .none
    
    var role: OwnerRole?
    var contractor: String = ""
    var checkType: CompletionCheckType = .none
    var checker: String = ""
    var deadline: Date?
    var bondType: PerformanceBondType?
    var encryption: Bool = true
    
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
        case .createDeal:
            create()
        case .copy:
            if let share = state.shareable?.shareContent {
                UIPasteboard.general.string = share
            }
        case .hideError:
            self.state.state = .none
        case .setRole(let role):
            state.role = role
        case .setContractor(let contractor):
            state.contractor = contractor
        case .setCheckType(let checkType):
            state.checkType = checkType
        case .setChecker(let checker):
            state.checker = checker
        case .setDeadline(let deadline):
            state.deadline = deadline
        case .setBondType(let bondType):
            state.bondType = bondType
        case .setEncryption(let encryption):
            state.encryption = encryption
        case .close:
            state.state = .close
        }
    }

    // MARK: - Private Methods

    private func create() {

        Task { @MainActor in
            guard let secret = try? await SharedSecretService.createSharedSecret(privateKey: state.account.privateKey) else {
                return
            }
            self.state.state = .creating
            let newDeal = NewDeal(
                role: state.role!,
                encryptedSecretKey: state.encryption ? secret.base64EncodedSecret : nil,
                secretKeyHash: state.encryption ? secret.hashOriginalKey : nil,
                sharedKey: state.encryption ? secret.serverSecret.base64EncodedString() : nil,
                performanceBondType: state.bondType ?? .none,
                completionCheckType: state.checkType,
                contractorPublicKey: state.contractor.isEmpty ? nil : state.contractor,
                checkerPublicKey: state.checker.isEmpty ? nil : state.checker,
                deadline: state.deadline
            )

            do {
                let deal = try await self.createDeal(deal: newDeal)
                var newState = self.state
                if state.encryption {
                    newState.shareable = ShareableDeal(dealId: deal.id, secretBase64: secret.clientSecret.base64EncodedString())
                }
                newState.state = .success
                newState.createdDeal = deal
                self.state = newState
            } catch {
                self.state.state = .error(error.localizedDescription)
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
