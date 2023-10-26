import Foundation
import ContractusAPI
import Combine

extension TokenSelectViewModel {

    enum Mode {
        case single, many, select
    }
    
    struct State {
        enum State: Equatable  {
            case loading, loaded
        }

        let allowHolderMode: Bool
        let mode: Mode
        let tier: Balance.Tier
        var tokens: [ContractusAPI.Token] = []
        var selectedTokens: [ContractusAPI.Token]
        var disableUnselectTokens: [ContractusAPI.Token] = []
        var balances: [String: String] = [:]
        var state: State = .loaded

        func isSelected(_ token: ContractusAPI.Token) -> Bool {
            selectedTokens.contains(token)
        }

        func isDisableUnselect(_ token: ContractusAPI.Token) -> Bool {
            disableUnselectTokens.contains(token)
        }
    }

    enum Input {
        case load, search(String), select(ContractusAPI.Token), deselect(ContractusAPI.Token)
    }
}

final class TokenSelectViewModel: ViewModel {

    @Published private(set) var state: State

    private var resourcesAPIService: ContractusAPI.ResourcesService?
    private var tokens: [ContractusAPI.Token] = []
    private var balance: Balance?

    init(
        allowHolderMode: Bool,
        mode: Mode,
        tier: Balance.Tier,
        selectedTokens: [ContractusAPI.Token],
        disableUnselectTokens: [ContractusAPI.Token],
        balance: Balance?,
        resourcesAPIService: ContractusAPI.ResourcesService?
    ) {

        self.state = .init(
            allowHolderMode: allowHolderMode,
            mode: mode, tier: tier,
            selectedTokens: selectedTokens,
            disableUnselectTokens: disableUnselectTokens)

        self.balance = balance
        
        self.resourcesAPIService = resourcesAPIService
    }

    func trigger(_ input: Input, after: AfterTrigger? = nil) {

        switch input {
        case .load:
            state.state = .loading
            Task {
                let tokens = (try? await loadTokens()) ?? []
                let balances = Dictionary(uniqueKeysWithValues: (self.balance?.tokens ?? []).filter{ $0.amount.value > 0 }.map{ ($0.amount.token.code, $0.amount.valueFormattedWithCode) } )

                await MainActor.run { [tokens, balances] in
                    var state = self.state
                    state.balances = balances
                    state.tokens = tokens
                    state.state = .loaded
                    self.tokens = tokens
                    self.state = state
                }
            }
        case .search(let text):
            if text.isEmpty {
                self.state.tokens = self.tokens
                return
            }
            let searchText = text.uppercased()
            self.state.tokens = self.tokens.filter({
                ($0.name ?? "").uppercased().contains(searchText) || $0.code.uppercased().contains(searchText)
            })
        case .select(let token):
            switch state.mode {
            case .many:
                self.state.selectedTokens.append(token)
            case .single, .select:
                self.state.selectedTokens = [token]
            }
        case .deselect(let token):
            self.state.selectedTokens = self.state.selectedTokens.filter {$0.address != token.address }
        }
    }

    private func loadTokens() async throws -> [ContractusAPI.Token] {
        try await withCheckedThrowingContinuation { continues in
            self.resourcesAPIService?.tokens(type: .full, completion: { result in
                switch result {
                case .failure(let error):
                    continues.resume(throwing: error)
                case .success(let tokens):
                    if self.state.mode == .single {
                        continues.resume(returning: tokens.filter { $0.address != nil } )
                    } else {
                        continues.resume(returning: tokens)
                    }

                }
            })
        }
    }
}
