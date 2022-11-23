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
    case openFile(MetadataFile)
    case updateContent(DealMetadata, DealsService.ContentType)
    case sign
    case none
    case saveKey(String)
}

struct DealState {

    enum State: Equatable {
        case loading, error(String), success, none, filePreview(URL)
    }
    
    let account: CommonAccount
    var deal: ContractusAPI.Deal
    var canEdit: Bool = true
    var canSign: Bool = true
    var state: State = .none
    var partnerSecretPartBase64: String = ""
    var decryptedKey = Data()
    var decryptedFilesMetadata: [MetadataFile] = []
    var decryptedFilesResult: [MetadataFile] = []

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
        deal.checkerPublicKey == account.publicKey || (deal.checkerPublicKey == nil && isOwnerDeal && ownerIsClient)
    }

    var canSendResult: Bool {
        deal.status == .working && isYouExecutor
    }

    var showResult: Bool {
        deal.status == .working
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



    private var dealService: ContractusAPI.DealsService?
    private var transactionSignService: TransactionSignService?
    private var filesAPIService: ContractusAPI.FilesService?
    private var secretStorage: SharedSecretStorage?
    private var cancelable = Set<AnyCancellable>()
    
    private var metadata: DealMetadata?
    private var encryptedFile: UploadFileResult?

    init(
        state: DealState,
        dealService: ContractusAPI.DealsService?,
        transactionSignService: TransactionSignService?,
        filesAPIService: ContractusAPI.FilesService?,
        secretStorage: SharedSecretStorage?)
    {
        debugPrint(state.deal)
        self.state = state
        self.dealService = dealService
        self.filesAPIService = filesAPIService
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
                    self.state.decryptedKey = key
                    try? self.secretStorage?.saveSharedSecret(for: self.state.deal.id, sharedSecret: key)
                }
                .store(in: &cancelable)
            
        case .sign:
            signTransaction()
        case .changeAmount(let amount):
            state.deal.amount = amount.value
            state.deal.currency = amount.currency
        case .update(let deal):
            if let deal = deal {
                self.state.deal = deal
                return
            }
            guard let dealService = dealService else { return }
            dealService.getDeal(id: state.deal.id) { result in
                switch result {
                case .success(let deal):
                    self.state.deal = deal
                case .failure(let error):
                    break
                }
            }
        case .updateContent(let content, let contentType):
            switch contentType {
            case .metadata:
                state.deal.meta = content
            case .result:
                state.deal.results = content
            }
        case .openFile(let file):
            Task {
                guard let url = await prepareFileForPreview(file) else { return }
                await MainActor.run {
                     state.state = .filePreview(url)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func checkAvailableDecrypt() {
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
                    self.state.decryptedKey = key
                }
                .store(in: &cancelable)
        }
    }

    private func decryptKey() {
        guard let key = state.deal.encryptedSecretKey else { return }
        Crypto.decrypt(base64Encrypted: key, with: state.account.privateKey)
            .flatMap({ secretKey -> Future<(Data, String), Error> in
                Future { promise in
                    do {
                        let sharedSecrets = try SSS.createShares(data: [UInt8](secretKey), n: 2, k: 2)
                        let partnerSecretPartBase64 = Data(sharedSecrets.last ?? []).base64EncodedString()
                        promise(.success((secretKey, partnerSecretPartBase64)))
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
                    self.state.decryptedKey = Data()
                case .finished:
                    break
                }

            } receiveValue: { (decryptedKey, partnerSecretPartBase64) in
                self.state.decryptedKey = decryptedKey
                self.state.partnerSecretPartBase64 = partnerSecretPartBase64
                self.state.canEdit = true
            }.store(in: &cancelable)

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

    private func downloadFile(url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation({ (callback: CheckedContinuation<URL, Error>) in
            self.filesAPIService?.download(url: url, progressCallback: { _ in
            }, completion: { result in
                switch result {
                case .success(let path):
                    callback.resume(returning: path)
                case .failure(let error):
                    callback.resume(throwing: error)
                }
            })
        })
    }

    private func prepareFileForPreview(_ file: MetadataFile) async -> URL? {
        let fileNameData = try? await Crypto.decrypt(base64Encrypted: file.name, with: state.account.privateKey)
        guard let fileNameData = fileNameData else { return nil }
        guard let fileName = String(data: fileNameData, encoding: .utf8) else { return nil }
        guard let filePath = try? await downloadFile(url: file.url) else { return nil }
        guard let fileEncryptedData = try? Data(contentsOf: filePath) else { return nil }
        guard let fileData = try? await Crypto.decrypt(encryptedData: fileEncryptedData, with: state.account.privateKey) else { return nil }
        let documentsURL = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try? fileData.write(to: fileURL)
        return fileURL
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

            }.store(in: &cancelable)
    }
}

extension MetadataFile: Identifiable {
    public var id: String {
        return self.url.lastPathComponent
    }

    var formattedSize: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(self.size))
    }
}
