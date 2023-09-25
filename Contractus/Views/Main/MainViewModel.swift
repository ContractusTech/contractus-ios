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
    case load(MainState.DealType)
    case loadDeals(MainState.DealType)
    case executeScanResult(ScanResult)
    case saveTokenSettings([ContractusAPI.Token])
}

struct MainState {

    enum DealType: Identifiable, CaseIterable {
        var id: String { "\(self)" }
        case all, isExecutor, isClient, isChecker, isWorking, isDone, isCanceled
    }

    enum DealsState {
        case loading, loaded
    }

    var account: CommonAccount
    var statistics: [ContractusAPI.AccountStatistic] = []
    var balance: Balance?
    var deals: [ContractusAPI.Deal] = []
    var dealsState: DealsState = .loading
    var selectedTokens: [ContractusAPI.Token] = []
    var disableUnselectTokens: [ContractusAPI.Token] = []
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
        self.state = MainState(account: account, selectedTokens: UtilsStorage.shared.getTokenSettings() ?? [])

        self.accountAPIService = accountAPIService
        self.dealsAPIService = dealsAPIService
        self.resourcesAPIService = resourcesAPIService
        self.accountStorage = accountStorage
    }

    func trigger(_ input: MainInput, after: AfterTrigger? = nil) {
        switch input {
        case .saveTokenSettings(let tokens):
            UtilsStorage.shared.saveTokenSettings(tokens: tokens)
            Task {
                try? await loadAccountInfo()
            }

        case .preload:
            Task {
                try? await loadAccountInfo()
            }
        case .load(let type):
            state.dealsState = .loading
            guard dealsAPIService != nil else {
                state.dealsState = .loaded
                return
            }
            // TODO: - Refactor, need parallel requests
            Task { @MainActor in
                try? await loadAccountInfo()

                var state = self.state

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
            var statuses: Set<ContractusAPI.DealsService.FilterByStatus> = .init(arrayLiteral: .new, .started, .starting, .finishing, .finished, .canceling, .revoked, .canceled)
            switch type {
            case .isChecker:
                types = .init(arrayLiteral: .isChecker)
            case .isClient:
                types = .init(arrayLiteral: .isClient)
            case .isExecutor:
                types = .init(arrayLiteral: .isExecutor)
            case .isWorking:
                types = .init()
                statuses = .init(arrayLiteral: .started)
            case .isDone:
                types = .init()
                statuses = .init(arrayLiteral: .finished)
            case .isCanceled:
                types = .init()
                statuses = .init(arrayLiteral: .canceled, .revoked)
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

    private func loadBalance(for tokens: [ContractusAPI.AccountService.Token]) async throws -> Balance {
        try await withCheckedThrowingContinuation { continues in

            let request = ContractusAPI.AccountService.BalanceRequest(tokens: tokens)
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

    private func getTokenSettings() async -> [ContractusAPI.Token] {
        if let tokens = UtilsStorage.shared.getTokenSettings() {
            return tokens
        }

        if let tokens = try? await loadTokens() {
            UtilsStorage.shared.saveTokenSettings(tokens: tokens)
            return tokens
        }
        return []
    }

    @MainActor
    private func loadAccountInfo() async throws {
        self.tokens = await getTokenSettings()

        var state = self.state

        switch state.account.blockchain {
        case .solana:
            // TODO: - Need refactor.
            state.disableUnselectTokens = self.tokens.filter { $0.native || $0.code == "WSOL" }
        }

        async let balanceTask = loadBalance(for: tokens.map { .init(code: $0.code, address: $0.address) })
        async let statisticsTask = loadStatistics(currency: .defaultCurrency)

        let (statistics, balance) = try await (statisticsTask, balanceTask)
        state.selectedTokens = self.tokens
        state.balance = balance
        state.statistics = statistics

        self.state = state

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
