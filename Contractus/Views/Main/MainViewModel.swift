//
//  MainViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 01.08.2022.
//

import Foundation
import ContractusAPI
import SolanaSwift
import Combine

enum MainInput {
    case preload
    case loadBalance
    case load(MainState.DealType)
    case loadDeals(MainState.DealType)
    case executeScanResult(ScanResult)
}

struct MainState {

    enum DealType: Identifiable, CaseIterable {
        var id: String { "\(self)" }
        case all, isExecutor, isClient, isChecker
    }

    enum DealsState {
        case loading, loaded
    }

    var account: CommonAccount
    var balance: Balance?
    var deals: [ContractusAPI.Deal] = []
    var dealsState: DealsState = .loading
    var availableTokens: [ContractusAPI.Token] = []
}

final class MainViewModel: ViewModel {

    @Published private(set) var state: MainState

    private var resourcesAPIService: ContractusAPI.ResourcesService?
    private var accountAPIService: ContractusAPI.AccountService?
    private var dealsAPIService: ContractusAPI.DealsService?
    private var store = Set<AnyCancellable>()
    private var tokens: [ContractusAPI.Token] = []

    init(
        account: CommonAccount,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?,
        resourcesAPIService: ContractusAPI.ResourcesService?)
    {
        self.state = MainState(account: account)
        self.accountAPIService = accountAPIService
        self.dealsAPIService = dealsAPIService
        self.resourcesAPIService = resourcesAPIService
    }

    func trigger(_ input: MainInput, after: AfterTrigger? = nil) {
        switch input {
        case .preload:
            Task { @MainActor in
                self.tokens = (try? await loadTokens()) ?? []
                self.state.availableTokens = self.tokens.filter({ $0.address != nil })
                let balance = try? await loadBalance()
                self.state.balance = balance
                after?()
            }
        case .loadBalance:
            Task { @MainActor in
                let balance = try? await loadBalance()
                self.state.balance = balance
                after?()
            }
        case .load(let type):
            state.dealsState = .loading
            Task { @MainActor in
                self.tokens = (try? await loadTokens()) ?? []
                let balance = try? await loadBalance()
                self.state.balance = balance
            }
            Task { @MainActor in
                let deals = try? await self.loadDeals(type: type)
                self.state.deals = deals ?? []
                self.state.dealsState = .loaded
                after?()
            }
        case .loadDeals(let type):
            Task { @MainActor in
                let deals = try? await self.loadDeals(type: type)
                self.state.deals = deals ?? []
                self.state.dealsState = .loaded
                after?()
            }

        case .executeScanResult(let result):
            debugPrint(result)
        }
    }

    // MARK: - Private Methods

    private func loadDeals(type: MainState.DealType) async throws -> [Deal] {
        try await withCheckedThrowingContinuation { continues in

            var types: Set<ContractusAPI.DealsService.FilterByRole>
            var statuses: Set<ContractusAPI.DealsService.FilterByStatus> = .init(arrayLiteral: .new, .working, .pending)
            switch type {
            case .isChecker:
                types = .init(arrayLiteral: .isChecker)
            case .isClient:
                types = .init(arrayLiteral: .isClient)
            case .isExecutor:
                types = .init(arrayLiteral: .isExecutor)
            case .all:
                types = .init()
            }

            dealsAPIService?.getDeals(pagination: .init(skip: 0, take: 100, types: types, statuses: statuses), completion: { result in
                switch result {
                case .success(let deals):
                    continues.resume(returning: deals)
                case .failure(let error):
                    continues.resume(throwing: error)
                }
            })
        }
    }

    private func loadBalance() async throws -> Balance {
        try await withCheckedThrowingContinuation { continues in
            let request = ContractusAPI.AccountService.BalanceRequest(
                tokens: self.tokens.map({ .init(code: $0.code, address: $0.address) }))
            accountAPIService?.getBalance(request, completion: { result in
                switch result {
                case .failure(let error):
                    continues.resume(throwing: error)
                case .success(let balance):
                    continues.resume(returning: balance)
                }
            })
        }
    }

    private func loadTokens() async throws -> [ContractusAPI.Token] {
        try await withCheckedThrowingContinuation { continues in
            resourcesAPIService?.tokens(completion: { result in
                switch result {
                case .failure(let error):
                    continues.resume(throwing: error)
                case .success(let tokens):
                    continues.resume(returning: tokens)
                }
            })
        }
    }

}
