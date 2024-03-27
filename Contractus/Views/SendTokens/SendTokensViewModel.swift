import Foundation
import ContractusAPI

extension SendTokensViewModel {

    struct State {

        enum State: Equatable {
            case ready, loading
        }

        enum ErrorState: Equatable {
            case error(String)
        }

        let account: CommonAccount
        let currency: Currency

        var tokens: [ContractusAPI.Token] = []
        var balance: Balance?
        var transactionSignType: TransactionSignType?
        var errorState: ErrorState?
        var state: Self.State = .ready
        var selectedToken: ContractusAPI.Token?
        var tokenInfo: ContractusAPI.Balance.TokenInfo?
        var recipient: String = ""

        var amount: String = ""
        var amountFormatted: String = ""
        var convertedAmount: String = ""
        var convertedFormatted: String = ""
        var reversed: Bool = false
        var notEnough: Bool {
            if let maxAmount = tokenInfo?.amount.valueFormatted.double, ((maxAmount < amount.double && maxAmount > 0) || maxAmount == 0)  {
                return true
            } else {
                return false
            }
        }
        var blockchain: Blockchain = .solana
        var isValidImportedPrivateKey: Bool = false
    }

    enum Input {
        case selectToken(Token), setRecipient(String), setAmount(String), swap, send, hideError, setMaxAmount, validateRecipient(String)
    }
}

final class SendTokensViewModel: ViewModel {

    @Published private(set) var state: State
    private var accountAPIService: ContractusAPI.AccountService?
    private var transactionsService: ContractusAPI.TransactionsService?
    private let accountService: AccountService

    init(
        state: SendTokensViewModel.State,
        accountAPIService: ContractusAPI.AccountService?,
        transactionsService: ContractusAPI.TransactionsService?,
        accountService: AccountService
    ) {
        self.accountAPIService = accountAPIService
        self.transactionsService = transactionsService
        self.accountService = accountService
        self.state = state
    }

    func trigger(_ input: Input, after: AfterTrigger? = nil) {

        switch input {
        case .setMaxAmount:
            if state.reversed {
                swap()
            }
            if let maxAmount = state.tokenInfo?.amount.valueFormatted {
                updateAmount(amount: maxAmount)
            }
        case .swap:
            swap()
        case .setAmount(let amount):
            updateAmount(amount: amount)
        case .setRecipient(let recipient):
            state.recipient = recipient
        case .validateRecipient(let recipient):
            guard let account = try? accountService.restore(by: recipient, blockchain: state.blockchain) else {
                self.state.isValidImportedPrivateKey = false
                return
            }
            self.state.isValidImportedPrivateKey = true

        case .selectToken(let token):
            state.selectedToken = token
            clearAmount()
            Task { @MainActor in
                if let selectedToken = self.state.selectedToken {
                    if let tokenInfo = state.balance?.tokens.first(where: { item in
                        item.amount.token == selectedToken
                    }) {
                        state.tokenInfo = tokenInfo
                    } else {
                        state.balance = try? await loadBalance(for: [.init(code: selectedToken.code, address: selectedToken.address)])
                        if let tokenInfo = state.balance?.tokens.first(where: { item in
                            if selectedToken.native {
                                item.amount.token.native
                            } else {
                                item.amount.token == selectedToken
                            }

                        }) {
                            state.tokenInfo = tokenInfo
                        }
                    }

                }
            }
        case .send:
            guard let token = state.selectedToken, !state.recipient.isEmpty else {
                return
            }
            guard let amount = AmountFormatter.format(string: state.reversed ? state.convertedAmount : state.amount, token: token) else {
                return
            }

            state.state = .loading

            let transferData = ContractusAPI.TransactionsService.TransferTransaction(
                value: amount,
                token: .init(code: token.code, address: token.address),
                recipient: state.recipient
            )

            Task { @MainActor in
                do {
                    let tx = try await transfer(data: transferData)
                    state.transactionSignType = .byTransaction(tx)
                    after?()
                } catch {
                    state.errorState = .error(error.localizedDescription)
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

    private func swap() {

        var state = state
        let newAmount = state.convertedAmount
        let newAmountFormatted = state.convertedFormatted

        let newConverted = state.amount
        let newConvertedFormatted = state.amountFormatted

        state.amount = newAmount
        state.amountFormatted = newAmountFormatted
        state.convertedAmount = newConverted
        state.convertedFormatted = newConvertedFormatted
        state.reversed = !state.reversed
        self.state = state
    }

    private func updateAmount(amount: String) {

        var state = state
        if state.reversed {            
            let amountDouble = amount.double
            state.convertedAmount = tokenAmountFormatted(amount: amountDouble, withCode: false)
            state.convertedFormatted = tokenAmountFormatted(amount: amountDouble, withCode: true)
            state.amountFormatted = state.tokenInfo?.currency.format(double: amountDouble, withCode: true) ?? ""
        } else {
            let amountDouble = amount.double
            state.convertedAmount = fiatAmountFormatted(amount: amountDouble, withCode: false)
            state.convertedFormatted = fiatAmountFormatted(amount: amountDouble, withCode: true)
            state.amountFormatted = tokenAmountFormatted(amount: amountDouble, withCode: true)
        }

        state.amount = amount
        self.state = state
    }

    private func fiatAmountFormatted(amount: Double, withCode: Bool) -> String {
        let symbol = state.tokenInfo?.currency.symbol ?? ""
        let price = state.tokenInfo?.price ?? 0.0
        if withCode {
            return "\(symbol) \((price * amount).rounded(to: 2).formatted())".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "\((price * amount).rounded(to: 2).formatted())".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenAmountFormatted(amount: Double, withCode: Bool) -> String {
        let price = state.tokenInfo?.price ?? 0.0
        let symbol = state.selectedToken?.code ?? ""
        if withCode {
            return "\((amount / price).formatted()) \(symbol)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "\((amount / price).formatted())".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearAmount() {
        self.state.amount = ""
        self.state.amountFormatted = ""
        self.state.convertedAmount = ""
        self.state.convertedFormatted = ""
    }
}
