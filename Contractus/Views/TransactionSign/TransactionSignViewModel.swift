import Foundation
import ContractusAPI
import web3swift
import Web3Core
import BigInt

enum TransactionSignType: Equatable, Identifiable {
    var id: String { "\(self)" }
    case byDeal(Deal, ContractusAPI.TransactionType)
    case byTransactionId(String)
    case byTransaction(ContractusAPI.Transaction)
}

enum TransactionSignInput {
    case sign
    case hideError
    case openExplorer
    case approve
    case load
}

struct TransactionSignState {

    enum ErrorState: Equatable {
        case error(String)
        case approveError
    }

    enum State {
        case loading, loaded, signing, signed, approving
    }

    struct InformationItem: Equatable, Identifiable {
        var id: String {
            return "\(self)"
        }

        let title: String
        let value: String

        let titleDescription: String?
        let valueDescription: String?

    }

    let account: CommonAccount
    var state: State
    var approveTXs: ApprovalAmount?
    var errorState: ErrorState?
    var type: TransactionSignType
    var transaction: Transaction?
    var approveStatus: TransactionStatus?
    var informationFields: [InformationItem]
    var allowSign: Bool = false
    var needFunds: Bool = false
    var needFundsTokens: String = ""
    var maxGasAmount: String = ""

    var isOwnerDeal: Bool {
        switch type {
        case .byDeal(let deal, _):
            return deal.ownerPublicKey == account.publicKey
        case .byTransactionId:
            return transaction?.initializerPublicKey == account.publicKey
        case .byTransaction(let tx):
            return tx.initializerPublicKey == account.publicKey
        }
    }
    var needApprove: Bool {
        approveTXs?.needApproval ?? false
    }
}

final class TransactionSignViewModel: ViewModel {

    enum TransactionError: Error {
        case transactionIsNull
        case approveError
        case notSupportTransaction
    }

    @Published private(set) var state: TransactionSignState

    private var pollTxService: PollService<Transaction>?
    private var approvePollGroup = PollGroup<ExternalTransaction>()
    private var pollApproveTxService: PollService<ExternalTransaction>?
    private var pollServicedApproveTxService: PollService<ExternalTransaction>?
    private var dealService: ContractusAPI.DealsService?
    private var accountService: ContractusAPI.AccountService?
    private var transactionSignService: TransactionSignService?
    private var transactionsService: ContractusAPI.TransactionsService?

    init(
        account: CommonAccount,
        type: TransactionSignType,
        dealService: ContractusAPI.DealsService? = nil,
        accountService: ContractusAPI.AccountService? = nil,
        transactionSignService: TransactionSignService? = nil,
        transactionsService: ContractusAPI.TransactionsService? = nil
    ) {

        self.dealService = dealService
        self.transactionSignService = transactionSignService
        self.accountService = accountService
        self.transactionsService = transactionsService

        switch type {
        case .byDeal(let deal, let txType):
            self.state = .init(
                account: account,
                state: .loading,
                type: type,
                informationFields: Self.fieldsByDeal(deal, txType: txType, account: account))

        case .byTransactionId:
            fatalError("No implementation .byTransactionId(let id)")
        case .byTransaction(let tx):
            self.state = .init(account: account, state: .loaded, type: type, transaction: tx, informationFields: Self.fieldsForTx(tx, account: account))
            self.state.allowSign = true
            self.initPollTxService(id: tx.id)
        }
    }

    deinit {
        pollTxService?.endPoll()
        pollApproveTxService?.endPoll()
        pollServicedApproveTxService?.endPoll()
    }

    func trigger(_ input: TransactionSignInput, after: AfterTrigger?) {
        switch input {
        case .load:
            switch self.state.type {
            case .byDeal(let deal, let txType):
                Task { @MainActor in
                    do {
                        var newState = self.state

                        let tx = try await getTx()
                        newState.transaction = tx

                        let fundStatus = try await getFundsStatus()

                        newState.needFunds = fundStatus.needFunds
                        newState.needFundsTokens = fundStatus.needFundsTokens
                        newState.maxGasAmount = fundStatus.maxGasAmount
                        newState.approveTXs = fundStatus.approveTXs

                        if let tx = tx {
                            initPollTxService(id: tx.id)
                            if let fee = tx.fee, txType == .dealInit {
                                newState.informationFields.append(.init(
                                    title: R.string.localizable.transactionSignFieldsFee(),
                                    value: deal.allowHolderMode ?? false ? R.string.localizable.transactionSignFieldsFreeFee() : deal.token.format(amount: fee, withCode: true),
                                    titleDescription: nil,
                                    valueDescription: nil
                                ))
                            }
                        }

                        if let allowHolderMode = deal.allowHolderMode, allowHolderMode && txType == .dealInit {
                            newState.informationFields.append(.init(
                                title: R.string.localizable.transactionSignFieldsHolderMode(),
                                value: R.string.localizable.commonOn(),
                                titleDescription: R.string.localizable.transactionSignSubtitleHolderMode(),
                                valueDescription: nil
                            ))
                        }
                        var value: String?
                        switch deal.performanceBondType {
                        case .both:
                            if deal.ownerRole == .client {
                                value = R.string.localizable.transactionSignFieldsBondTypeBoth(deal.contractorBondFormatted(withCode: true), deal.ownerBondFormatted(withCode: true))
                            } else {
                                value = R.string.localizable.transactionSignFieldsBondTypeBoth(deal.ownerBondFormatted(withCode: true), deal.contractorBondFormatted(withCode: true))
                            }
                        case .onlyClient:
                            if deal.ownerRole == .client {
                                value = R.string.localizable.transactionSignFieldsBondTypeClient(deal.ownerBondFormatted(withCode: true))
                            } else {
                                value = R.string.localizable.transactionSignFieldsBondTypeClient(deal.contractorBondFormatted(withCode: true))
                            }
                        case .onlyExecutor:
                            if deal.ownerRole == .client {
                                value = R.string.localizable.transactionSignFieldsBondTypeExecutor(deal.contractorBondFormatted(withCode: true))
                            } else {
                                value = R.string.localizable.transactionSignFieldsBondTypeExecutor(deal.ownerBondFormatted(withCode: true))
                            }
                        case .none:
                            break
                        }

                        if deal.performanceBondType != .none  && txType == .dealInit {
                            newState.informationFields.append(.init(
                                title: R.string.localizable.transactionSignFieldsBond(),
                                value: value ?? "",
                                titleDescription: deal.performanceBondType.shortTitle,
                                valueDescription: nil
                            ))
                        }
                        
                        newState.state = .loaded
                        newState.allowSign = !newState.needFunds
                        self.state = newState
                    } catch {
                        var newState = self.state
                        newState.errorState = .error(error.localizedDescription)
                        newState.state = .loaded
                        newState.allowSign = false
                        self.state = newState
                    }
                }
            case .byTransactionId:
                break
            case .byTransaction(let tx):
                self.state.allowSign = true
                self.initPollTxService(id: tx.id)
            }

        case .approve:
            guard state.needApprove else { return }

            self.state.state = .approving
            Task { @MainActor in
                do {
                    try await approveIfNeeded()

                    var newState = self.state
                    self.state = newState
                    
                } catch(let error) {
                    var newState = self.state
                    newState.state = .loaded
                    newState.errorState = .error(error.localizedDescription)
                    self.state = newState
                }
            }
        case .hideError:
            state.errorState = nil
        case .openExplorer:
            guard let signature = state.transaction?.signature else { return }
            BlockchainExplorer.openExplorer(blockchain: state.account.blockchain, txSignature: signature)
        case .sign:
            self.state.state = .signing

            Task { @MainActor in
                do {
                    let transaction = try await sign()
                    var newState = self.state
                    newState.errorState = nil
                    newState.state = .signed
                    if let transaction = transaction {
                        newState.transaction = transaction
                    }
                    self.state = newState
                    pollTxService?.startPoll()
                } catch {
                    var newState = self.state
                    newState.state = .loaded
                    newState.errorState = .error(error.localizedDescription)
                    self.state = newState
                }
            }
        }
    }

    private func getApproveTxIfNeeded(deal: Deal, tx: Transaction, account: CommonAccount) async -> [String]? {
        guard isNeedApprove(for: deal, txType: tx.type, account: account) else { return nil }
        var addresses = Set<String>()

        if let address = tx.token?.address{
            addresses.insert(address)
        }

        let alreadyRequest = tx.token?.serviced ?? false
        if !alreadyRequest && deal.allowHolderMode ?? false
            || ((deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey) || (deal.ownerRole == .executor && deal.contractorPublicKey == account.publicKey)) {

            addresses.insert("serviced") // serviced == CTUS check by backend
        }

        switch deal.performanceBondType {
        case .both:
            if deal.ownerPublicKey == account.publicKey {
                if let address = deal.ownerBondToken?.address {
                    addresses.insert(address)
                }
            } else if deal.contractorPublicKey == account.publicKey {
                if let address = deal.ownerBondToken?.address {
                    addresses.insert(address)
                }
            }
        case .onlyClient:
            if deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey {
                if let address = deal.ownerBondToken?.address {
                    addresses.insert(address)
                }
            } else if deal.ownerRole == .executor && deal.contractorPublicKey == account.publicKey {
                if let address = deal.contractorBondToken?.address {
                    addresses.insert(address)
                }
            }
        case .onlyExecutor:
            if deal.ownerRole == .executor && deal.ownerPublicKey == account.publicKey {
                if let address = deal.ownerBondToken?.address {
                    addresses.insert(address)
                }
            } else if deal.ownerRole == .client && deal.contractorPublicKey == account.publicKey {
                if let address = deal.contractorBondToken?.address {
                    addresses.insert(address)
                }
            }
        case .none:
            break
        }

        return Array(addresses)
    }

    private func getFundsStatus() async throws -> (needFunds: Bool, needFundsTokens: String, needApprove: Bool, maxGasAmount: String, approveTXs: ApprovalAmount?) {
        var needFunds = false
        var approveTXs: ApprovalAmount?
        var needFundsTokens: String = ""
        var maxGasAmount = ""

        let funds = try? await checkFunds()
        if let addresses = funds?.needApprove.compactMap({ $0.address }), !addresses.isEmpty {
            approveTXs = try await self.checkApprove(for: addresses )
        }

        if let codes = funds?.needFunds, !codes.isEmpty {
            needFunds = true
            needFundsTokens = codes.map {$0.code}.joined(separator: ",")
        } else {
            needFunds = false
            needFundsTokens = ""
        }

        if let approveTXs = approveTXs, approveTXs.maxGas > BigUInt(0) {
            maxGasAmount = approveTXs.token.format(amount: approveTXs.maxGas, withCode: true)
        }

        return (
            needFunds: needFunds,
            needFundsTokens: needFundsTokens,
            needApprove: !maxGasAmount.isEmpty,
            maxGasAmount: maxGasAmount,
            approveTXs: approveTXs
        )
    }

    private func getExternalTxPollRequest(_ signature: String, callback: ((ExternalTransaction?) -> Void)? = nil) -> PollService<ExternalTransaction> {
        let request: PollService<ExternalTransaction> = .init(request: {[weak self] cb in
            self?.transactionsService?.getExternalTransaction(signature) { result in
                switch result {
                case .success(let tx):
                    cb(.success(tx))
                case .failure(let error):
                    cb(.failure(error))
                }
            }
        })

        request.handler = { tx in
            callback?(tx)
            if tx?.status == .finished {
                return .success
            } else if tx?.status == .error {
                return .error()
            }
            return .wait
        }
        return request
    }

    private func approveIfNeeded() async throws {
        var requests = [PollService<ExternalTransaction>]()

        for tx in state.approveTXs?.rawTransactions ?? [] {
            let result = try await self.sendApprove(unsignedTx: tx, signer: state.account)
            if let signature = result.data?.signature {
                requests.append(getExternalTxPollRequest(signature))
            }
        }
        approvePollGroup.reset()
        approvePollGroup.add(requests)
        approvePollGroup.didFinish = { result in
            switch result {
            case .allSuccess, .allError, .someError:
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    let fundStatus = try await getFundsStatus()
                    var newState = self.state
                    newState.needFunds = fundStatus.needFunds
                    newState.needFundsTokens = fundStatus.needFundsTokens
                    newState.maxGasAmount = fundStatus.maxGasAmount
                    newState.approveTXs = fundStatus.approveTXs

                    if result == .allError || result == .someError {
                        newState.errorState = .error("Some errors in approve. Please, try again.")
                    }

                    self.state = newState
                }
            }

        }

        approvePollGroup.startAll()
    }

    private func initPollTxService(id: String) -> Void {
        guard let transactionsService = self.transactionsService else { return }
        self.pollTxService = .init(request: { callback in
            transactionsService.getTransaction(id: id) { result in
                switch result {
                case .success(let tx):
                    callback(.success(tx))
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        })
        self.pollTxService?.handler = {[weak self] tx in
            self?.state.transaction = tx
            if tx?.status == .finished {
                ImpactGenerator.success()
                return .success
            } else if tx?.status == .error {
                ImpactGenerator.error()
                return .error()
            }
            return .wait
        }
    }

    private func isNeedApprove(for deal: ContractusAPI.Deal, txType: ContractusAPI.TransactionType, account: CommonAccount) -> Bool {
        guard txType == .dealInit else { return false }

        switch deal.performanceBondType {
        case .both:
            return deal.ownerPublicKey == account.publicKey || deal.contractorPublicKey == account.publicKey
        case .onlyClient, .none:
            return (deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey)
            || (deal.ownerRole == .executor && deal.contractorPublicKey == account.publicKey)
        case .onlyExecutor:
            return (deal.ownerRole == .executor && deal.ownerPublicKey == account.publicKey)
            || (deal.ownerRole == .client && deal.contractorPublicKey == account.publicKey)
        }
    }

    private func getTx() async throws -> Transaction? {
        guard case .byDeal(let deal, let type) = state.type else { return nil }
        return try await withCheckedThrowingContinuation({ [weak self] continuation in
            self?.dealService?.getTransaction(dealId: deal.id,  silent: false, type: type, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    private func checkApprove(for tokenAddresses: [String]) async throws -> ApprovalAmount? {
        guard state.account.blockchain == .bsc else { return nil }
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.transactionsService?.getApprovalAmountTransaction(for: Array(Set(tokenAddresses)), completion: { result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    private func sendApprove(unsignedTx: ApprovalUnsignedTransaction, signer: Signer) async throws -> TransactionResult {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            do {

                let signedTx = try self?.transactionSignService?.sign(tx: unsignedTx, by: signer, type: .common)

                guard let signedTx = signedTx else {
                    continuation.resume(throwing: TransactionSignServiceError.failed)
                    return
                }

                self?.transactionsService?.approveAmountTransaction(.init(rawTransaction: unsignedTx, signature: signedTx.signature), completion: { result in
                    switch result {
                    case .success(let result):
                        continuation.resume(returning: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            } catch(let error) {
                continuation.resume(throwing: error)

            }
        }
    }

    private func checkFunds() async throws -> CheckFunds {
        switch state.type {
        case .byDeal(let deal, _):
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self = self else { return }
                self.dealService?.checkFunds(dealId: deal.id, completion: { result in
                    switch result {
                    case .success(let funds):
                        continuation.resume(returning: funds)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        case .byTransaction, .byTransactionId:
            throw TransactionError.notSupportTransaction
        }

    }

    private func sign() async throws -> Transaction? {
        switch state.type {
        case .byDeal(let deal, _):
            return try await withCheckedThrowingContinuation({ [weak self] continuation in

                guard let transaction = self?.state.transaction, let account = self?.state.account else {
                    continuation.resume(throwing: TransactionError.transactionIsNull)
                    return
                }

                guard let signedTx = try? self?.transactionSignService?.sign(tx: transaction, by: account, type: .byType(transaction.type)) else {
                    continuation.resume(throwing: TransactionError.transactionIsNull)
                    return
                }

                self?.dealService?.signTransaction(dealId: deal.id, type: transaction.type, data: signedTx, completion: { result in
                    continuation.resume(with: result)
                })
            })
        case .byTransaction(let tx):
            return try await withCheckedThrowingContinuation({ continuation in
                guard let signedTx = try? transactionSignService?.sign(tx: tx, by: self.state.account, type: .byType(tx.type)) else {
                    continuation.resume(throwing: TransactionError.transactionIsNull)
                    return
                }

                switch tx.type {
                case .wrapSOL, .wrap:
                    transactionsService?.signWrap(.init(id: tx.id, transaction: signedTx.transaction, signature: signedTx.signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .unwrapAllSOL, .unwrap:
                    transactionsService?.signUnwrapAll(.init(id: tx.id, transaction: signedTx.transaction, signature: signedTx.signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .transfer:
                    transactionsService?.transferSign(.init(id: tx.id, transaction: signedTx.transaction, signature: signedTx.signature), completion: {result in
                        continuation.resume(with: result)
                    })
                case .dealFinish, .dealInit, .dealCancel:
                    continuation.resume(throwing: TransactionError.transactionIsNull)

                }
            })
        case .byTransactionId(_):
            fatalError("No implementation")
        }
    }

    static private func fieldsByDeal(_ deal: Deal, txType: ContractusAPI.TransactionType, account: CommonAccount) -> [TransactionSignState.InformationItem] {

        var fields: [TransactionSignState.InformationItem] = [
            .init(
                title: R.string.localizable.transactionSignFieldsType() ,
                value: txType.title,
                titleDescription: nil,
                valueDescription: nil),
        ]
        switch txType {
        case .dealInit:
            fields.append(.init(
                title: R.string.localizable.transactionSignFieldsAmount(),
                value: deal.token.format(amount: deal.amount, withCode: true),
                titleDescription: nil,
                valueDescription: nil))
            if deal.ownerRole == .client && deal.ownerPublicKey == account.publicKey {
                fields.insert(.init(
                    title: R.string.localizable.transactionSignFieldsClient(),
                    value: ContentMask.mask(from: deal.ownerPublicKey),
                    titleDescription: nil,
                    valueDescription: nil
                ), at: 0)
                if let contractorPublicKey = deal.contractorPublicKey {
                    fields.insert(.init(
                        title: R.string.localizable.transactionSignFieldsExecutor(),
                        value:  ContentMask.mask(from: contractorPublicKey),
                        titleDescription: nil,
                        valueDescription: nil
                    ), at: 1)
                }
                if let checkerPublicKey = deal.checkerPublicKey {
                    fields.insert(.init(
                        title: R.string.localizable.transactionSignFieldsChecker(),
                        value:  ContentMask.mask(from: checkerPublicKey),
                        titleDescription: nil,
                        valueDescription: nil
                    ), at: 2)
                }
            } else {
                fields.insert(.init(
                    title: R.string.localizable.transactionSignFieldsClient(),
                    value: ContentMask.mask(from: deal.ownerPublicKey),
                    titleDescription: nil,
                    valueDescription: nil
                ), at: 0)
                if let contractorPublicKey = deal.contractorPublicKey {
                    fields.insert(.init(
                        title: R.string.localizable.transactionSignFieldsExecutor(),
                        value:  ContentMask.mask(from: contractorPublicKey),
                        titleDescription: nil,
                        valueDescription: nil
                    ), at: 1)
                }
                if let checkerPublicKey = deal.checkerPublicKey {
                    fields.insert(.init(
                        title: R.string.localizable.transactionSignFieldsChecker(),
                        value:  ContentMask.mask(from: checkerPublicKey),
                        titleDescription: nil,
                        valueDescription: nil
                    ), at: 2)
                }
            }
            if let checkerAmount = deal.checkerAmount {
                fields.append(.init(
                    title: R.string.localizable.transactionSignFieldsVerifierFee(),
                    value: deal.token.format(amount: checkerAmount, withCode: true),
                    titleDescription: nil,
                    valueDescription: nil)
                )
            }
            return fields
        case .dealFinish:
            return fields
        case .dealCancel:
            return fields
        case .wrapSOL, .wrap:
            return fields
        case .unwrapAllSOL, .unwrap:
            return fields
        case .transfer:
            return fields
        }
    }

    static private func fieldsForTx(_ tx: Transaction, account: CommonAccount) -> [TransactionSignState.InformationItem] {
        var fields: [TransactionSignState.InformationItem] = [
            .init(
                title: R.string.localizable.transactionSignFieldsType(),
                value: tx.type.title,
                titleDescription: nil,
                valueDescription: nil),
        ]

        switch tx.type {
        case .transfer:
            fields.append(.init(
                title: R.string.localizable.transactionSignFieldsAmount(),
                value: tx.amountFormatted ?? "",
                titleDescription: nil,
                valueDescription: nil))
            if let feeFormatted = tx.feeFormatted {
                fields.append(.init(
                    title: R.string.localizable.transactionSignFieldsFee(),
                    value: feeFormatted,
                    titleDescription: nil,
                    valueDescription: nil))
            }
        case .wrapSOL,.unwrapAllSOL, .wrap, .unwrap:
            fields.append(.init(
                title: R.string.localizable.transactionSignFieldsAmount(),
                value: tx.amountFormatted ?? "",
                titleDescription: nil,
                valueDescription: nil))
            if let feeFormatted = tx.feeFormatted {
                fields.append(.init(
                    title: R.string.localizable.transactionSignFieldsFee(),
                    value: feeFormatted,
                    titleDescription: nil,
                    valueDescription: nil))
            }

        case .dealCancel, .dealFinish:
            break
        case .dealInit:
            if let fee = tx.feeFormatted {
                fields.append(.init(
                    title: R.string.localizable.transactionSignFieldsServiceFee(),
                    value: fee,
                    titleDescription: nil,
                    valueDescription: nil))
            } else {
                fields.append(.init(
                    title: R.string.localizable.transactionSignFieldsFee(),
                    value: R.string.localizable.transactionSignFieldsFreeFee(),
                    titleDescription: nil,
                    valueDescription: nil))
            }
        }

        return fields
    }
}

private extension ContractusAPI.TransactionType {
    var title: String {
        switch self {
        case .wrapSOL, .wrap: return R.string.localizable.transactionTypeWrapSol()
        case .dealInit: return R.string.localizable.transactionTypeInitDeal()
        case .dealCancel: return R.string.localizable.transactionTypeCancelDeal()
        case .dealFinish: return R.string.localizable.transactionTypeFinishDeal()
        case .unwrapAllSOL, .unwrap: return R.string.localizable.transactionTypeUnwrapWsol()
        case .transfer: return R.string.localizable.transactionTypeTransfer()
        }
    }
}
