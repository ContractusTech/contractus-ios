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
    case changeCheckerAmount(Amount)
    case update(Deal?)
    case openFile(MetadataFile)
    case updateContent(DealMetadata, DealsService.ContentType)
    case deleteMetadataFile(MetadataFile)
    case deleteResultFile(MetadataFile)
    case cancel
    case cancelDownload
    case none
    case saveKey(ScanResult)
}

struct DealState {

    enum State: Equatable {
        case loading, error(String), success, none
    }
    enum FileState: Equatable {
        case filePreview(URL), none, downloading(Double), decrypting
    }

    enum MainActionType {
        /// Can sign contract
        case sign
        /// Deal in work and user want cancel contract (return amount from smart contract)
        case cancelDeal
        /// Deal in work and user want finish contract, executor get payment
        case finishDeal
        /// Deal not working yet and user want cancel your sign
        case cancelSign
        /// Not action
        case none
    }

    let account: CommonAccount
    var deal: ContractusAPI.Deal
    var shareDeal: ShareableDeal?
    var canEdit: Bool = false
    var canSign: Bool = true
    var state: State = .none
    var previewState: FileState = .none
    var partnerSecretPartBase64: String = ""
    var decryptedKey = Data()
    var decryptedFiles: [String:URL] = [:]
    var decryptingFiles: [String:Bool] = [:]
    var isSigned: Bool? = nil



    var isOwnerDeal: Bool {
        deal.ownerPublicKey == account.publicKey
    }

    var youIsClient: Bool {
        deal.ownerRole == .client ? deal.ownerPublicKey == account.publicKey : deal.contractorPublicKey == account.publicKey
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

    var isYouChecker: Bool {
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

    var currentMainAction: MainActionType {
        .none
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
    private var downloadingUUID: UUID?

    init(
        state: DealState,
        dealService: ContractusAPI.DealsService?,
        transactionSignService: TransactionSignService?,
        filesAPIService: ContractusAPI.FilesService?,
        secretStorage: SharedSecretStorage?)
    {
        self.state = state
        self.dealService = dealService
        self.filesAPIService = filesAPIService
        self.transactionSignService = transactionSignService
        self.secretStorage = secretStorage
        self.loadActualTx()
        self.checkAvailableDecrypt()
    }

    func trigger(_ input: DealInput, after: AfterTrigger? = nil) {
        switch input {
        case .cancel:
            state.state = .loading
            dealService?.cancel(dealId: state.deal.id, force: false, completion: { [weak self] result in
                self?.state.state = .none
                switch result {
                case .failure(let error):
                    self?.state.state = .error(error.localizedDescription)
                case .success(let deal):
                    after?()
                }
            })
        case .none:
            state.state = .none

        case .saveKey(let importResult):
            switch importResult {
            case .publicKey:
                break
            case .deal(let shareData):
                guard shareData.command == .shareDealSecret else {
                    return
                }
                recoverSharedKey(partnerKey: shareData.secretBase64)
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
            }

        case .changeAmount(let amount):
            state.deal.amount = amount.value
            state.deal.currency = amount.currency
        case .changeCheckerAmount(let amount):
            state.deal.checkerAmount = amount.value
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
            state.previewState = .none
            guard !state.decryptedKey.isEmpty, !(state.decryptingFiles[file.md5] ?? false) else { return }
            state.decryptingFiles[file.md5] = true
            Task {
                guard let url = await prepareFileForPreview(file) else {
                    debugPrint("Error open file")
                    await MainActor.run {
                        state.decryptingFiles[file.md5] = nil
                        state.decryptedFiles[file.md5] = nil
                    }
                    return

                }
                await MainActor.run {
                    state.decryptedFiles[file.md5] = url
                    state.decryptingFiles[file.md5] = nil
                    state.previewState = .filePreview(file.url)
                    after?()
                }
            }
        case .deleteMetadataFile(let file):
            state.state = .loading
            let meta = DealMetadata(
                content: state.deal.meta?.content,
                files: state.deal.meta?.files.filter({ $0 != file }) ?? [])
            dealService?.update(
                dealId: state.deal.id,
                typeContent: .metadata,
                meta: UpdateDealMetadata(meta: meta, updatedAt: Date(), force: true),
                completion: {[weak self] result in
                    self?.state.deal.meta = meta
                    self?.state.state = .none
                })

        case .deleteResultFile(_):
            break
        case .cancelDownload:
            guard let downloadingUUID = downloadingUUID else { return }
            state.previewState = .none
            filesAPIService?.cancelDownload(by: downloadingUUID)
        }
    }

    // MARK: - Private Methods

    private func loadActualTx() {
        Task {
            guard let tx = try? await getActualTx() else { return }
            var signature: String?
            if state.isOwnerDeal {
                signature = tx.ownerSignature
            } else if state.deal.contractorPublicKey == self.state.account.publicKey {
                signature = tx.contractorSignature
            }

            guard let signature = signature else {
                await MainActor.run(body: {[weak self] in
                    self?.state.isSigned = false
                })
                return
            }
            let isSigned = transactionSignService?.isSigned(txBase64: tx.transaction, signatureBase64: signature, publicKey: state.account.publicKeyData) ?? false
            await MainActor.run(body: {[weak self, isSigned] in
                self?.state.isSigned = isSigned
            })

        }
    }

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
                self.state.shareDeal = ShareableDeal(dealId: self.state.deal.id, secretBase64: partnerSecretPartBase64)
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

    private func getActualTx() async throws -> DealTransaction? {
        try await withCheckedThrowingContinuation({ continuation in
            dealService?.getActualTransaction(dealId: state.deal.id, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    private func downloadFile(url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation({ (callback: CheckedContinuation<URL, Error>) in
            let uuid = self.filesAPIService?.download(url: url, progressCallback: { progress in
                Task {
                    await MainActor.run { [weak self] in
                        self?.state.previewState = .downloading(progress)
                    }
                }

            }, completion: { result in
                switch result {
                case .success(let path):
                    callback.resume(returning: path)
                case .failure(let error):
                    callback.resume(throwing: error)
                }
            })
            DispatchQueue.main.async { [weak self] in
                self?.downloadingUUID = uuid
            }
        })
    }

    private func prepareFileForPreview(_ file: MetadataFile) async -> URL? {
        await MainActor.run {
            state.previewState = .downloading(0)
        }
        let fileNameData = try? await Crypto.decrypt(base64Encrypted: file.name, with: state.decryptedKey)
        guard let fileNameData = fileNameData else { debugPrint("fileNameData is empty"); return nil }
        guard let fileName = String(data: fileNameData, encoding: .utf8) else { debugPrint("fileName is empty"); return nil }
        guard let filePath = try? await downloadFile(url: file.url) else { debugPrint("downloadFile error"); return nil }

        await MainActor.run {
            state.previewState = .decrypting
        }
        guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil}
        let folderURL = documentsURL.appendingPathComponent(filePath.lastPathComponent, isDirectory: true)
        let fileURL = folderURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        guard let fileEncryptedData = try? Data(contentsOf: filePath) else { return nil }
        guard let fileData = try? await Crypto.decrypt(encryptedData: fileEncryptedData, with: state.decryptedKey) else { debugPrint("Decrypt error"); return nil }

//        do {
//            try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true)
//        } catch {
//            debugPrint(error.localizedDescription)
//        }

        do {
            try? FileManager.default.removeItem(at: fileURL)
            try fileData.write(to: fileURL)
            return fileURL
        } catch(let error) {
            debugPrint(error.localizedDescription)
            return nil
        }

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
