//
//  TransactionSignViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 04.01.2023.
//

import Foundation
import ContractusAPI
import web3swift
import Web3Core

enum TransactionSignType: Equatable, Identifiable {
    var id: String { "\(self)" }
    case byDeal(Deal, ContractusAPI.TransactionType)
    case byTransactionId(String)
    case byTransaction(ContractusAPI.Transaction)
}

enum TransactionSignError: Error {
    case transactionIsNull
}

enum TransactionSignInput {
    case sign
    case hideError
    case openExplorer
    case approve
}

struct TransactionSignState {

    enum ErrorState: Equatable {
        case error(String)
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
    var approveTx: ApprovalAmount?
    var errorState: ErrorState?
    var type: TransactionSignType
    var transaction: Transaction?
    var informationFields: [InformationItem]
    var allowSign: Bool = false
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
        return self.approveTx?.needApproval ?? false
    }
}

final class TransactionSignViewModel: ViewModel {

    @Published private(set) var state: TransactionSignState

    private var pollTxService: PollService<Transaction>?
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
            Task { @MainActor in
                do {

                    let tx = try await getTx()
                    var newState = self.state

                    if let address = tx?.token?.address, let checkApproveTx = try? await checkApprove(for: address) {
                        newState.approveTx = checkApproveTx
                    }

                    newState.transaction = tx
                    newState.state = .loaded
                    newState.allowSign = true
                    if let tx = tx {
                        initPollTxService(id: tx.id)
                        if let fee = tx.fee, txType == .dealInit {
                            newState.informationFields.append(.init(
                                title: R.string.localizable.transactionSignFieldsFee(),
                                value: deal.token.format(amount: fee, withCode: true),
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
            fatalError("No implementation .byTransactionId(let id)")
        case .byTransaction(let tx):
            self.state = .init(account: account, state: .loaded, type: type, transaction: tx, informationFields: Self.fieldsForTx(tx, account: account))
            self.state.allowSign = true
            self.initPollTxService(id: tx.id)
        }
    }

    deinit {
        pollTxService?.endPoll()
    }

    func trigger(_ input: TransactionSignInput, after: AfterTrigger?) {
        switch input {
        case .approve:
            guard let tx = state.approveTx else { return }
            self.state.state = .approving
            Task { @MainActor in
                do {
                    try await self.sendApprove(tx: tx, signer: state.account)
                    var newState = self.state
                    newState.approveTx = nil
                    newState.state = .loaded
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

    private func initPollTxService(id: String) -> Void {
        guard let transactionsService = self.transactionsService else { return }
        self.pollTxService = .init(request: { callback in
            transactionsService.getTransaction(id: id) { [weak self] result in
                switch result {
                case .success(let tx):
                    callback(tx)
                case .failure(let error):
                    debugPrint(error)
                    self?.pollTxService?.endPoll()
                }
            }
        })
        self.pollTxService?.handler = {[weak self] tx in
            self?.state.transaction = tx
            if tx?.status == .finished {
                ImpactGenerator.success()
                self?.pollTxService?.endPoll()
            } else if tx?.status == .error {
                ImpactGenerator.error()
                self?.pollTxService?.endPoll()
            }
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

    private func checkApprove(for tokenAddress: String) async throws -> ApprovalAmount? {
        guard state.account.blockchain == .bsc else { return nil }
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.transactionsService?.getApprovalAmountTransaction(for: tokenAddress, completion: { result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }

    }

    private func sendApprove(tx: ApprovalAmount, signer: Signer) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            do {
                guard let unsignedTx = tx.rawTransaction else {
                    continuation.resume(throwing: TransactionSignServiceError.transactionIsEmpty)
                    return
                }

                let signature = try self?.transactionSignService?.sign(tx: unsignedTx, by: signer, type: .common)

                guard let signature = signature else {
                    continuation.resume(throwing: TransactionSignServiceError.failed)
                    return
                }

                self?.transactionsService?.approveAmountTransaction(.init(rawTransaction: unsignedTx, signature: signature), completion: { result in
                    switch result {
                    case .success(let success):
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            } catch(let error) {
                continuation.resume(throwing: error)

            }
        }
    }


    private func sign() async throws -> Transaction? {
        switch state.type {
        case .byDeal(let deal, _):
            return try await withCheckedThrowingContinuation({ continuation in
                guard let transaction = state.transaction else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }

                guard let signature = try? transactionSignService?.sign(tx: transaction, by: self.state.account, type: .byType(transaction.type)) else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }

                dealService?.signTransaction(dealId: deal.id, type: transaction.type, data: .init(transaction: transaction.transaction, signature: signature), completion: { result in
                    continuation.resume(with: result)
                })
            })
        case .byTransaction(let tx):
            return try await withCheckedThrowingContinuation({ continuation in
                guard let signature = try? transactionSignService?.sign(tx: tx, by: self.state.account, type: .byType(tx.type)) else {
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)
                    return
                }

                switch tx.type {
                case .wrapSOL, .wrap:
                    transactionsService?.signWrap(.init(id: tx.id, transaction: tx.transaction, signature: signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .unwrapAllSOL, .unwrap:
                    transactionsService?.signUnwrapAll(.init(id: tx.id, transaction: tx.transaction, signature: signature), completion: { result in
                        continuation.resume(with: result)
                    })
                case .transfer:
                    transactionsService?.transferSign(.init(id: tx.id, transaction: tx.transaction, signature: signature), completion: {result in
                        continuation.resume(with: result)
                    })
                case .dealFinish, .dealInit, .dealCancel:
                    continuation.resume(throwing: TransactionSignError.transactionIsNull)

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
                    title: R.string.localizable.transactionSignFieldsExecutor(),
                    value: ContentMask.mask(from: deal.ownerPublicKey),
                    titleDescription: nil,
                    valueDescription: nil
                ), at: 0)
            } else {
                if let contractorPublicKey = deal.contractorPublicKey {
                    fields.insert(.init(
                        title: R.string.localizable.transactionSignFieldsExecutor(),
                        value:  ContentMask.mask(from: contractorPublicKey),
                        titleDescription: nil,
                        valueDescription: nil
                    ), at: 0)
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
