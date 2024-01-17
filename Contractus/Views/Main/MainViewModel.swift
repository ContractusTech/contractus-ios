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
    case load(MainState.DealType, silent: Bool = false)
    case loadDeals(MainState.DealType)
    case executeScanResult(ScanResult)
    case saveTokenSettings([ContractusAPI.Token])
    case selectDeal(deal: Deal?, isNew: Bool = false)
}

struct MainState {

    enum DealType: Identifiable, CaseIterable {
        var id: String { "\(self)" }
        case all, isExecutor, isClient, isChecker, isWorking, isDone, isCanceled
    }

    enum DealsState {
        case loading, loaded
    }
    var selectedDeal: Deal?
    var selectedDealIsNew: Bool = false
    var account: CommonAccount
    var checkoutMethods: [ContractusAPI.CheckoutType] = []
    var allowBuyToken: Bool = false
    var allowDeposit: Bool = false
    var currency: Currency = .defaultCurrency
    var statistics: [ContractusAPI.AccountStatistic] = []
    var balance: Balance?
    var deals: [ContractusAPI.Deal] = []
    var dealsState: DealsState = .loading
    var selectedTokens: [ContractusAPI.Token] = []
    var disableUnselectTokens: [ContractusAPI.Token] = []
}

final class MainViewModel: ViewModel {

    @Published private(set) var state: MainState

    private var openDealNotification: NSObjectProtocol?
    private var resourcesAPIService: ContractusAPI.ResourcesService?
    private var accountAPIService: ContractusAPI.AccountService?
    private var dealsAPIService: ContractusAPI.DealsService?
    private var checkoutService: ContractusAPI.CheckoutService?
    private var secretStorage: SharedSecretStorage?
    private var accountStorage: AccountStorage
    private var store = Set<AnyCancellable>()
    private var tokens: [ContractusAPI.Token] = []

    init(
        account: CommonAccount,
        accountStorage: AccountStorage,
        accountAPIService: ContractusAPI.AccountService?,
        dealsAPIService: ContractusAPI.DealsService?,
        resourcesAPIService: ContractusAPI.ResourcesService?,
        checkoutService: ContractusAPI.CheckoutService?,
        secretStorage: SharedSecretStorage?,
        notification: NotificationHandler.NotificationType? = nil)
    {
        self.state = MainState(account: account, selectedTokens: UtilsStorage.shared.getTokenSettings(blockchain: account.blockchain) ?? [])

        self.accountAPIService = accountAPIService
        self.dealsAPIService = dealsAPIService
        self.resourcesAPIService = resourcesAPIService
        self.checkoutService = checkoutService
        self.accountStorage = accountStorage
        self.secretStorage = secretStorage
        Task { @MainActor in
            await requestAuthorization()
        }

        if let notification = notification {
            handleNotification(notification)
        }

        openDealNotification = NotificationCenter.default.addObserver(forName: NSNotification.openDeal, object: nil, queue: nil, using: {[weak self] notification in
            guard let self = self, let params = notification.object as? NotificationHandler.OpenDealParams else { return }

            self.handleNotification(.open(params))
        })
    }

    func trigger(_ input: MainInput, after: AfterTrigger? = nil) {
        switch input {
        case .selectDeal(let deal, let isNew):
            var state = state
            state.selectedDealIsNew = isNew
            state.selectedDeal = deal
            self.state = state

        case .saveTokenSettings(let tokens):
            UtilsStorage.shared.saveTokenSettings(tokens: tokens, blockchain: self.state.account.blockchain)
            Task {
                try? await loadAccountInfo()
            }

        case .preload:
            Task {
                try? await loadAccountInfo()
            }
        case .load(let type, let silent):
            if !silent {
                state.dealsState = .loading
            }

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
            switch result {
            case .deal(let shareData):
                Task { @MainActor in

                    switch shareData.command {
                    case .shareDealSecret:
                        guard let clientKeyData = Data(base64Encoded: shareData.secretBase64) else { return }

                        try? self.secretStorage?.saveSharedSecret(for: shareData.id, sharedSecret: clientKeyData)
                        guard
                            let deal = try? await loadDeal(id: shareData.id),
                            let serverKey = deal.sharedKey,
                            let serverKeyData = Data(base64Encoded: serverKey) else { return }

                        guard let secretData = try? await SharedSecretService.recover(serverSecret: serverKeyData, clientSecret: clientKeyData, hashOriginalKey: deal.secretKeyHash ?? "") else {
                            return
                        }
                        state.selectedDeal = deal
                    case .open:
                        break
                    }
                }

            case .publicKey:
                break
            }
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

    private func loadDeal(id: String) async throws -> Deal {
        try await withCheckedThrowingContinuation { continues in

            dealsAPIService?.getDeal(id: id, completion: { result in
                switch result {
                case .success(let deal):
                    continues.resume(returning: deal)
                case .failure(let error):
                    continues.resume(throwing: error)
                }
            })
        }
    }

    private func loadDeals(type: MainState.DealType) async throws -> [Deal] {
        try await withCheckedThrowingContinuation { continues in

            var types: Set<ContractusAPI.DealsService.FilterByRole>
            var statuses: Set<ContractusAPI.DealsService.FilterByStatus> = .init()
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
        if let tokens = UtilsStorage.shared.getTokenSettings(blockchain: self.state.account.blockchain) {
            return tokens
        }

        if let tokens = try? await loadTokens() {
            UtilsStorage.shared.saveTokenSettings(tokens: tokens, blockchain: self.state.account.blockchain)
            return tokens
        }
        return []
    }

    @MainActor
    private func loadAccountInfo() async throws {
        self.tokens = await getTokenSettings()

        var state = self.state
        state.disableUnselectTokens = self.tokens.filter { $0.native || $0.code == state.account.blockchain.wrapTokenCode }

        async let balanceTask = loadBalance(for: tokens.map { .init(code: $0.code, address: $0.address) })
        async let statisticsTask = loadStatistics(currency: .defaultCurrency)
        async let availableMethodsTask = loadAvailableMethods()

        let (statistics, balance, methods) = try await (statisticsTask, balanceTask, availableMethodsTask)
        state.selectedTokens = self.tokens
        state.balance = balance
        state.statistics = statistics
        state.checkoutMethods = methods
        state.allowBuyToken = methods.contains(.advcash)
        state.allowDeposit = methods.contains(.transak)
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

    private func loadAvailableMethods() async throws -> [ContractusAPI.CheckoutType] {
        try await withCheckedThrowingContinuation { continues in
            checkoutService?.available(completion: { result in
                switch result {
                case .failure(let error):
                    continues.resume(throwing: error)
                case .success(let data):
                    continues.resume(returning: data.methods)
                }
            })
        }
    }

    private func requestAuthorization() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    private func handleNotification(_ notification: NotificationHandler.NotificationType) {

        switch notification {
        case .open(let params):
            var accountExist = false
            if !params.recipients.contains(self.state.account.publicKey) {
                for publicKey in params.recipients {
                    guard let newAccount = AppManagerImpl.shared.getAccount(by: publicKey) else {
                        continue
                    }
                    AppManagerImpl.shared.setAccount(for: newAccount)
                    self.trigger(.updateAccount)
                    self.trigger(.preload)
                    self.trigger(.load(.all))
                    
                    accountExist = true
                    break
                }
            } else {
                accountExist = true
            }

            guard accountExist else { return }
            Task { @MainActor in
                self.state.selectedDeal = try? await self.loadDeal(id: params.dealId)
            }
        }

    }
}

extension Deal: Identifiable { }
