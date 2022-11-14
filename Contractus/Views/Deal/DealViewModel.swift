//
//  DealViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 18.08.2022.
//

import Foundation
import ContractusAPI
import SolanaSwift
import Combine
import BigInt

enum DealViewModelError: Error {
    case invalidSharedKey
}

enum DealInput {
    case changeAmount(Amount)
    case update(Deal?)
    case updateContent(String, Bool)
    case decryptContent
    case sign
    case none
    case saveKey(String)
}

struct DealState {

    enum State: Equatable {
        case loading, error(String), success, none, decryptedContent(String?), needConfirmForceUpdate
    }
    
    let account: CommonAccount
    var deal: ContractusAPI.Deal
    var canEdit: Bool = true
    var canSign: Bool = true
    var state: State = .none
    var sharedSecretBase64: String = ""

    var isOwnerDeal: Bool {
        deal.ownerPublicKey == account.publicKey
    }

    var partnerIsEmpty: Bool {
        deal.contractorPublicKey?.isEmpty ?? true
    }

    var checkerIsEmpty: Bool {
        deal.checkerPublicKey?.isEmpty ?? true
    }

    var clientIsChecker: Bool {
        deal.checkerPublicKey == deal.ownerPublicKey && deal.ownerRole == .client
    }

    var ownerIsClient: Bool {
        deal.ownerRole == .client
    }

    var isYouExecutor: Bool {
        deal.ownerRole == .client && deal.contractorPublicKey == account.publicKey
    }

    var isYouVerifier: Bool {
        deal.checkerPublicKey == account.publicKey
    }

    var clientPublicKey: String {
        switch deal.ownerRole {
        case .client:
            return deal.ownerPublicKey
        case .executor:
            return deal.contractorPublicKey ?? ""
        }
    }

    var executorPublicKey: String {
        switch deal.ownerRole {
        case .client:
            return deal.contractorPublicKey ?? ""
        case .executor:
            return deal.ownerPublicKey
        }
    }
}

final class DealViewModel: ViewModel {

    @Published private(set) var state: DealState

    private var decryptedKey: Data?

    private var dealService: ContractusAPI.DealsService?
    private var transactionSignService: TransactionSignService?
    private var secretStorage: SharedSecretStorage?
    private var store = Set<AnyCancellable>()
    private var startEditContent: Date?
    private var forceUpdateMeta: Bool = false

    init(
        state: DealState,
        dealService: ContractusAPI.DealsService?,
        transactionSignService: TransactionSignService?,
        secretStorage: SharedSecretStorage?)
    {
        debugPrint(state.deal)
        self.state = state
        self.dealService = dealService
        self.transactionSignService = transactionSignService
        self.secretStorage = secretStorage
        self.checkAvailableDecrypt()
    }

    func trigger(_ input: DealInput, after: AfterTrigger? = nil) {
        switch input {
        case .none:
            state.state = .none

        case .saveKey(let key):
            recoverSharedKey(partnerKey: key)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure:
                        self.state.canEdit = false
                    case .finished:
                        self.state.canEdit = true
                    }
                } receiveValue: { key in
                    self.decryptedKey = key
                    try? self.secretStorage?.saveSharedSecret(for: self.state.deal.id, sharedSecret: key)
                }
                .store(in: &store)
            
        case .sign:
            signTransaction()
        case .changeAmount(let amount):
            state.deal.amount = amount.value
            state.deal.currency = amount.currency
        case .update(let deal):
            guard let deal = deal else { return }
            self.state.deal = deal
        case .decryptContent:
            guard let text = self.state.deal.meta?.content?.text else {
                self.state.state = .decryptedContent(nil)
                return
            }
            startEditContent = Date()
            Crypto.decrypt(base64Encrypted: text, with: self.state.account.privateKey)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.state.state = .error(error.localizedDescription)
                    }
                } receiveValue: { data in
                    self.state.state = .decryptedContent(String(data: data, encoding: .utf8))
                }.store(in: &store)

        case .updateContent(let text, let force):
            self.state.state = .loading
            Crypto.encrypt(message: text, with: state.account.privateKey)
                .flatMap({ encryptedData in
                    Future<(String, String), Error> { promise in
                        let base64 = encryptedData.base64EncodedString()
                        promise(.success((base64, Crypto.md5(data: base64.data(using: .utf8)!))))
                    }
                })
                .flatMap({ (text, md5) in
                    Future<DealMetadata, Never> { promise in
                        let meta = DealMetadata(
                            content: TextContent(text: text, md5: md5),
                            files: self.state.deal.meta?.files ?? [])
                        promise(.success(meta))
                    }
                })
                .flatMap({ dealMeta in
                    self.updateMetadata(id: self.state.deal.id, meta: dealMeta, force: force)
                })
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        switch error as? ContractusAPI.APIClientError {
                        case .serviceError(let serviceError):
                            self.forceUpdateMeta = serviceError.statusCode == 409
                            self.state.state = .needConfirmForceUpdate
                        default:
                            self.state.state = .error(error.localizedDescription)
                        }

                    case .finished:
                        self.state.state = .none
                    }

                } receiveValue: { result in
                    self.state.deal.meta = result
                }.store(in: &store)
        }
    }

    func checkAvailableDecrypt() {
        if state.isOwnerDeal {
            decryptKey()
        } else {

            guard let partnerKeyData = secretStorage?.getSharedSecret(for: state.deal.id),
                  let key = String(data: partnerKeyData, encoding: .utf8) else { return }

            recoverSharedKey(partnerKey: key)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure:
                        self.state.canEdit = false
                    case .finished:
                        self.state.canEdit = true
                    }
                } receiveValue: { key in
                    self.decryptedKey = key
                }
                .store(in: &store)
        }
    }

    private func decryptKey() {
        guard let key = state.deal.encryptedSecretKey else { return }
        Crypto.decrypt(base64Encrypted: key, with: state.account.privateKey)
            .flatMap({ secretKey -> Future<(Data, String), Error> in
                Future { promise in
                    do {
                        let sharedSecrets = try SSS.createShares(data: [UInt8](secretKey), n: 2, k: 2)
                        let base64 = Data(sharedSecrets.last ?? []).base64EncodedString()
                        promise(.success((secretKey, base64)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            })
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure:
                    self.state.canEdit = false
                    self.decryptedKey = nil
                case .finished:
                    break
                }

            } receiveValue: { (decryptedKey, sharedSecretBase64) in
                self.decryptedKey = decryptedKey
                self.state.sharedSecretBase64 = sharedSecretBase64
                self.state.canEdit = true
            }.store(in: &store)

    }

    private func recoverSharedKey(partnerKey: String) -> Future<Data, Error> {
        Future { promise in
            guard
                let keyPart1 = self.state.deal.sharedKey,
                let part1Data = Data(base64Encoded: keyPart1),
                let part2Data = Data(base64Encoded: partnerKey),
                let hash = self.state.deal.secretKeyHash else { return promise(.failure(DealViewModelError.invalidSharedKey)) }

            do {
                let secretKey = try SSS.combineShares(data: [[UInt8](part1Data), [UInt8](part2Data)])
                let decryptKeyData = Data(secretKey!)
                if Crypto.checkSum(data: decryptKeyData, hashSHA3: hash) {
                    return promise(.success(decryptKeyData))
                } else {
                    promise(.failure(DealViewModelError.invalidSharedKey))
                    return
                }
            } catch {
                promise(.failure(error))
            }
        }
    }

    private func updateMetadata(id: String, meta: DealMetadata, force: Bool) -> Future<DealMetadata, Error> {
        Future { promise in
            self.dealService?.updateMetadata(dealId: id, meta: UpdateDealMetadata(
                meta: meta,
                updatedAt: self.startEditContent ?? Date(),
                force: force), completion: { result in
                switch result {
                case .success(let meta):
                    promise(.success(meta))
                case .failure(let error):
                    promise(.failure(error))
                }
            })
        }
    }

    private func getTransactions() -> Future<[DealTransaction], Error> {
        Future { promise in
            self.dealService?.transactions(dealId: self.state.deal.id, completion: { result in
                switch result {
                case .success(let tx):
                    promise(.success(tx))
                case .failure(let error):
                    promise(.failure(error as Error))
                }
            })

        }
    }

    private func getActualTransaction() -> Future<DealTransaction, Error> {
        Future { promise in
            self.dealService?.getActualTransaction(dealId: self.state.deal.id, completion: { result in
                switch result {
                case .success(let tx):
                    promise(.success(tx))
                case .failure(let error):
                    promise(.failure(error as Error))
                }
            })
        }
    }

    private func signTransaction() {
        guard
            let transactionSignService = transactionSignService,
            let dealService = dealService else { return }

        getActualTransaction()
            .flatMap { tx in
                Future<(String, TransactionType), Error> { promise in
                    do {
                        let signedTx = try transactionSignService.sign(
                            txBase64: tx.transaction,
                            by: self.state.account.privateKey)
                        promise(.success((signedTx, tx.type)))
                    } catch (let error) {
                        promise(.failure(error))
                    }
                }.eraseToAnyPublisher()
            }
            .flatMap({ tx, type in
                Future<DealTransaction, Error> { promise in
                    dealService.signTransaction(
                        dealId: self.state.deal.id,
                        type: type,
                        data: SignedDealTransaction(transaction: tx),
                        completion: { result in
                            switch result {
                            case .failure(let error):
                                promise(.failure(error as Error))
                            case .success(let data):
                                promise(.success(data))
                            }
                    })
                }
            })
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                }

            } receiveValue: { value in

            }.store(in: &store)
    }
}
