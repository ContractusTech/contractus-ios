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
    case updateAccount
    case preload
    case loadBalance
    case load(MainState.DealType)
    case loadDeals(MainState.DealType)
    case executeScanResult(ScanResult)
    case saveTokenSettings([ContractusAPI.Token])
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
    var statistics: [ContractusAPI.AccountStatistic] = []
    var balance: Balance?
    var deals: [ContractusAPI.Deal] = []
    var dealsState: DealsState = .loading
}

final class MainViewModel: ViewModel {

    @Published private(set) var state: MainState

    private var resourcesAPIService: ContractusAPI.ResourcesService?
    private var accountAPIService: ContractusAPI.AccountService?
    private var dealsAPIService: ContractusAPI.DealsService?
    private var accountStorage: AccountStorage
    private var store = Set<AnyCancellable>()
    private var tokens: [ContractusAPI.Token] = []

    init(
        account: CommonAccount,
        accountStorage: AccountStorage,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?,
        resourcesAPIService: ContractusAPI.ResourcesService?)
    {
        self.state = MainState(account: account)

        self.accountAPIService = accountAPIService
        self.dealsAPIService = dealsAPIService
        self.resourcesAPIService = resourcesAPIService
        self.accountStorage = accountStorage
    }

    func trigger(_ input: MainInput, after: AfterTrigger? = nil) {
        switch input {
        case .saveTokenSettings(let tokens):
            UtilsStorage.shared.saveTokenSettings(tokens: tokens)
            self.tokens = tokens
            Task { @MainActor in
                let accountInfo = try? await loadAccountInfo()
                self.state.balance = accountInfo?.balance
                self.state.statistics = accountInfo?.statistics ?? []
            }

        case .preload:
            Task { @MainActor in
                self.tokens = await getTokens()
                let accountInfo = try? await loadAccountInfo()
                self.state.balance = accountInfo?.balance
                self.state.statistics = accountInfo?.statistics ?? []
            }
        case .loadBalance:
            Task { @MainActor in
                self.state.balance = try? await loadBalance()
                after?()
            }
        case .load(let type):
            state.dealsState = .loading
            guard dealsAPIService != nil else {
                state.dealsState = .loaded
                return
            }
            // TODO: - Refactor, need parallel requests
            Task { @MainActor in
                var state = self.state
                self.tokens = await getTokens()
                let accountInfo = try? await loadAccountInfo()
                state.balance = accountInfo?.balance
                state.statistics = accountInfo?.statistics ?? []

                let deals = try? await self.loadDeals(type: type)
                state.deals = deals ?? []
                state.dealsState = .loaded

                self.state = state
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
        case .updateAccount:
            if let account = accountStorage.getCurrentAccount() {
                var newState = state
                newState.account = account
                newState.deals = []
                newState.balance = nil
                state = newState
            }
            after?()
        }
    }

    // MARK: - Private Methods

    private func loadDeals(type: MainState.DealType) async throws -> [Deal] {
        try await withCheckedThrowingContinuation { continues in

            var types: Set<ContractusAPI.DealsService.FilterByRole>
            let statuses: Set<ContractusAPI.DealsService.FilterByStatus> = .init(arrayLiteral: .new, .started, .starting, .finishing, .finished, .canceling, .revoked, .canceled)
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

    private func getTokens() async -> [ContractusAPI.Token] {
        if let tokens = UtilsStorage.shared.getTokenSettings() {
            return tokens
        }

        if let tokens = try? await loadTokens() {
            UtilsStorage.shared.saveTokenSettings(tokens: tokens)
            return tokens
        }
        return []
    }

    private func loadAccountInfo() async throws -> (statistics: [AccountStatistic], balance: Balance) {
        async let balance = loadBalance()
        async let statistics = loadStatistics(currency: .defaultCurrency)
        return try await (statistics, balance)
    }

    private func loadStatistics(currency: Currency) async throws -> [ContractusAPI.AccountStatistic] {
        try await withCheckedThrowingContinuation { continues in
            accountAPIService?.getStatistics(currency.code, completion: { result in
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
