import Foundation
import ContractusAPI

struct StepsState {
    var selectedToken: ContractusAPI.Token?
    var recipient: String = ""
    var amount: String = ""
}

extension SendTokensViewModel {

    struct State {

        enum State: Equatable {
            case ready, loading
        }

        enum ErrorState: Equatable {
            case error(String)
        }

        let account: CommonAccount
        var tokens: [ContractusAPI.Token] = []
        var stepsState = StepsState()
        var balance: Balance?
        var transactionSignType: TransactionSignType?
        var errorState: ErrorState?
        var state: Self.State = .ready

        var currency: String {
            let token = balance?.tokens.filter({ $0.amount.token.code == stepsState.selectedToken?.code}).first
            return token?.currency.code ?? ""
        }

        func getCost(amount: Double) -> String {
            let token = balance?.tokens.filter({ $0.amount.token.code == stepsState.selectedToken?.code}).first
            let price = token?.price ?? 0.0
            let symbol = token?.currency.symbol ?? ""
            return "\(symbol) \((price * amount).formatted())"            
        }

        func getCostReversed(amount: Double) -> String {
            let token = balance?.tokens.filter({ $0.amount.token.code == stepsState.selectedToken?.code}).first
            let price = token?.price ?? 0.0
            let symbol = token?.amount.token.code ?? ""
            return "\((amount / price).formatted()) \(symbol)"
        }
    }

    enum Input {
        case setState(StepsState), getBalance, send, hideError
    }
}

final class SendTokensViewModel: ViewModel {
    
    @Published private(set) var state: State
    private var accountAPIService: ContractusAPI.AccountService?
    private var transactionsService: ContractusAPI.TransactionsService?

    init(
        state: SendTokensViewModel.State,
        accountAPIService: ContractusAPI.AccountService?,
        transactionsService: ContractusAPI.TransactionsService?
    ) {
        self.accountAPIService = accountAPIService
        self.transactionsService = transactionsService
        self.state = state
    }
    
    func trigger(_ input: Input, after: AfterTrigger? = nil) {
        
        switch input {
        case .setState(let stepsState):
            state.stepsState = stepsState
        case .getBalance:
            Task { @MainActor in
                if let selectedToken = state.stepsState.selectedToken {
                    async let balanceTask = loadBalance(for: [.init(code: selectedToken.code, address: selectedToken.address)])
                    state.balance = try await balanceTask
                }
            }
        case .send:
            guard let token = state.stepsState.selectedToken else {
                return
            }
            guard let amount = AmountFormatter.format(string: state.stepsState.amount, token: token) else {
                return
            }
            let transferData = ContractusAPI.TransactionsService.TransferTransaction(
                value: amount,
                token: .init(code: token.code, address: token.address),
                recipient: state.stepsState.recipient
            )
            state.state = .loading
            Task { @MainActor in
                do {
                    let tx = try await transfer(data: transferData)
                    state.transactionSignType = .byTransaction(tx)
                    after?()
                } catch {
                    state.errorState = .error(error.readableDescription)
                }
                state.state = .ready
            }
        case .hideError:
            state.errorState = nil

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
    
    func transfer(data: ContractusAPI.TransactionsService.TransferTransaction) async throws -> Transaction {
        try await withCheckedThrowingContinuation({ continuation in
            transactionsService?.transfer(data, completion: { result in
                continuation.resume(with: result)
            })
        })
    }
}
