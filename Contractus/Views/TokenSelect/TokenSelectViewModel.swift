import Foundation
import ContractusAPI
import Combine

extension TokenSelectViewModel {

    enum Mode {
        case single, many
    }

    struct State {
        let allowHolderMode: Bool
        let mode: Mode
        let tier: Balance.Tier
        var tokens: [ContractusAPI.Token] = []
        var selectedTokens: [ContractusAPI.Token]
        var disableUnselectTokens: [ContractusAPI.Token] = []

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

    init(
        allowHolderMode: Bool,
        mode: Mode,
        tier: Balance.Tier,
        selectedTokens: [ContractusAPI.Token],
        disableUnselectTokens: [ContractusAPI.Token],
        resourcesAPIService: ContractusAPI.ResourcesService?
    ) {

        self.state = .init(
            allowHolderMode: allowHolderMode,
            mode: mode, tier: tier,
            selectedTokens: selectedTokens,
            disableUnselectTokens: disableUnselectTokens)

        self.resourcesAPIService = resourcesAPIService
    }

    func trigger(_ input: Input, after: AfterTrigger? = nil) {

        switch input {
        case .load:
            Task { @MainActor in
                self.tokens = (try? await loadTokens()) ?? []
                self.state.tokens = self.tokens
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
            case .single:
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
