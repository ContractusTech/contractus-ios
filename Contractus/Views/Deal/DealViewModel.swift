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
    case errorDealUpdated
}

enum DealInput {
    case changeAmount(Amount)
    case changeCheckerAmount(Amount)
    case update(Deal?)
    case updateTx
    case openFile(MetadataFile)
    case updateContent(DealMetadata, DealsService.ContentType)
    case deleteMetadataFile(MetadataFile)
    case deleteResultFile(MetadataFile)
    case cancel
    case cancelDownload
    case cancelSign
    case none
    case saveKey(ScanResult)
    case hideError
    case sheetClose
    case finishDeal
    case uploaderContentType(DealsService.ContentType?)
}

struct DealState {

    enum State: Equatable {
        case loading, success, none
    }

    enum ErrorState: Equatable {
        case error(String)
    }
    enum FileState: Equatable {
        case filePreview(URL), none, downloading(Double), decrypting
    }

    enum MainActionType: Int, Identifiable {
        var id: Int { return self.rawValue }

        /// Can sign contract
        case sign
        /// Deal in work and user want cancel contract (return amount from smart contract)
        case cancelDeal
        /// Deal in work and user want finish contract, executor get payment
        case finishDeal
        /// Deal not working yet and user want cancel your sign
        case cancelSign
    }

    let account: CommonAccount
    let availableTokens: [ContractusAPI.Token]
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
    var isSignedByPartner: Bool = false
    var errorState: ErrorState?
    var uploaderContentType: DealsService.ContentType?

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
        deal.checkerPublicKey == account.publicKey
    }

    var ownerIsClient: Bool {
        deal.ownerRole == .client
    }

    var ownerIsExecutor: Bool {
        deal.ownerRole == .executor
    }

    var isYouExecutor: Bool {
        (deal.ownerRole == .client && deal.contractorPublicKey == account.publicKey) ||
        deal.ownerRole == .executor && deal.ownerPublicKey == account.publicKey
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

    var currentMainActions: [MainActionType] = []
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
        self.state.state = .none
        self.dealService = dealService
        self.filesAPIService = filesAPIService
        self.transactionSignService = transactionSignService
        self.secretStorage = secretStorage
        self.loadActualTx()
        self.checkAvailableDecrypt()
    }

    func trigger(_ input: DealInput, after: AfterTrigger? = nil) {
        switch input {
        case .hideError:
            state.errorState = nil
        case .cancelSign:
            Task { @MainActor in
                do {
                    state.state = .loading
                    try await cancelSign()
                    loadActualTx()

                } catch(let error) {
                    state.errorState = .error(error.readableDescription)
                    state.state = .none
                }
            }
        case .cancel:
            state.state = .loading
            dealService?.cancel(dealId: state.deal.id, force: false, completion: { [weak self] result in
                self?.state.state = .none
                switch result {
                case .failure(let error):
                    self?.state.errorState = .error(error.localizedDescription)
                case .success(let deal):
                    after?()
                }
            })
        case .finishDeal:
            state.state = .loading
        case .none:
            state.state = .none
        case .sheetClose:
            state.previewState = .none
        case .saveKey(let importResult):
            switch importResult {
            case .publicKey:
                break
            case .deal(let shareData):
                guard shareData.command == .shareDealSecret else { return }
                Task { @MainActor in
                    guard
                        let clientKeyData = Data(base64Encoded: shareData.secretBase64),
                        let secretKey = await recoverSharedKey(clientKeyData: clientKeyData)
                    else {
                        self.state.canEdit = false
                        return
                    }
                    self.state.canEdit = true
                    self.state.decryptedKey = secretKey
                    try? self.secretStorage?.saveSharedSecret(for: self.state.deal.id, sharedSecret: clientKeyData)
                }
            }

        case .changeAmount(let amount):
            state.deal.amount = amount.value
            state.deal.token = amount.token
        case .changeCheckerAmount(let amount):
            state.deal.checkerAmount = amount.value
        case .updateTx:
            loadActualTx()
        case .update(let deal):
            if let deal = deal {
                self.state.deal = deal
                return
            }
            Task { @MainActor in
                guard let deal = try? await getDeal() else { return }
                self.state.deal = deal
                loadActualTx()
                after?()
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
            if let url = state.decryptedFiles[file.md5] {
                state.decryptingFiles[file.md5] = nil
                state.previewState = .filePreview(url)
                after?()
            } else {
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
                        state.previewState = .filePreview(url)
                        after?()
                    }
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
        case .deleteResultFile(let file):
            state.state = .loading
            let results = DealMetadata(
                content: state.deal.results?.content,
                files: state.deal.results?.files.filter({ $0 != file }) ?? [])
            dealService?.update(
                dealId: state.deal.id,
                typeContent: .result,
                meta: UpdateDealMetadata(meta: results, updatedAt: Date(), force: true),
                completion: {[weak self] result in
                    self?.state.deal.results = results
                    self?.state.state = .none
                })
        case .cancelDownload:
            guard let downloadingUUID = downloadingUUID else { return }
            state.previewState = .none
            filesAPIService?.cancelDownload(by: downloadingUUID)
        case .finishDeal:
            Task {
                let tx = try? await getFinishTx()
            }
        case .uploaderContentType(let type):
            state.uploaderContentType = type
        }
    }

    // MARK: - Private Methods

    private func loadActualTx() {
        Task { @MainActor in
            do {
                let tx = try await getActualTx()
                var signature: String?
                var isSignedByPartner: Bool = false
                if state.isOwnerDeal {
                    signature = tx.ownerSignature
                    isSignedByPartner = tx.contractorSignature != nil
                } else if state.deal.contractorPublicKey == self.state.account.publicKey {
                    signature = tx.contractorSignature
                    isSignedByPartner = tx.ownerSignature != nil
                }

                guard let signature = signature else {
                    await MainActor.run(body: {[weak self, isSignedByPartner] in
                        self?.state.isSignedByPartner = isSignedByPartner
                        self?.state.currentMainActions = getDealActions(for: state.deal, isSigned: false)
                    })
                    return
                }
                let isSigned = transactionSignService?.isSigned(
                    txBase64: tx.transaction,
                    publicKey: state.account.publicKeyData) ?? false
                let actions = getDealActions(for: state.deal, isSigned: isSigned)
                await MainActor.run(body: {[weak self, actions, isSignedByPartner] in
                    self?.state.isSignedByPartner = isSignedByPartner
                    self?.state.currentMainActions = actions
                })
                
             } catch let error as ContractusAPI.APIClientError {
                switch error {
                case .serviceError(let info):
                    if info.statusCode == 404 {
                        await MainActor.run(body: {[weak self] in
                            self?.state.isSignedByPartner = false
                            self?.state.currentMainActions = [.sign]
                            self?.state.canSign = true
                        })
                        return
                    }
                    if info.statusCode == 405 {
                        await MainActor.run(body: {[weak self] in
                            self?.state.isSignedByPartner = false
                            self?.state.currentMainActions = [.sign]
                            self?.state.canSign = false
                            self?.state.state = .none

                        })
                        return
                    }
                case .commonError, .unknownError:
                    break
                }
            } catch {
                return
            }

        }
    }

    private func checkAvailableDecrypt() {
        if state.isOwnerDeal {
            decryptKey()
        } else {
            guard let clientSecret = secretStorage?.getSharedSecret(for: state.deal.id) else {
                self.state.canEdit = false
                return
            }
            Task { @MainActor in
                guard let secretKey = await recoverSharedKey(clientKeyData: clientSecret) else {
                    self.state.canEdit = false
                    return
                }
                self.state.decryptedKey = secretKey
                self.state.canEdit = true
                self.checkLocalFiles()
            }
        }
    }

    private func decryptKey() {
        guard let key = state.deal.encryptedSecretKey else { return }
        Task { @MainActor in

            guard let secret = try? await SharedSecretService.encryptSharedSecretKey(base64String:key, hashOriginalKey: state.deal.secretKeyHash,  privateKey:state.account.privateKey) else {
                self.state.canEdit = false
                self.state.decryptedKey = Data()
                return
            }

            let partnerSecretPartBase64 = secret.clientSecret.base64EncodedString()
            self.state.decryptedKey = secret.secretKey
            self.state.partnerSecretPartBase64 = partnerSecretPartBase64
            self.state.shareDeal = ShareableDeal(dealId: self.state.deal.id, secretBase64: partnerSecretPartBase64)
            self.state.canEdit = true

            self.checkLocalFiles()
        }
    }

    private func recoverSharedKey(clientKeyData: Data) async -> Data? {

        guard
            let serverKey = self.state.deal.sharedKey,
            let serverKeyData = Data(base64Encoded: serverKey)
        else {
            return nil
        }
        guard let secretData = try? await SharedSecretService.recover(serverSecret: serverKeyData, clientSecret: clientKeyData, hashOriginalKey: self.state.deal.secretKeyHash ?? "") else {
            return nil
        }

        return secretData
    }

    private func getDeal() async throws -> Deal {
        try await withCheckedThrowingContinuation({ continuation in
            guard let dealService = dealService else {
                continuation.resume(throwing: DealViewModelError.errorDealUpdated)
                return
            }
            dealService.getDeal(id: state.deal.id) { result in
                continuation.resume(with: result)
            }
        })
    }

    private func getActualTx() async throws -> ContractusAPI.Transaction {
        try await withCheckedThrowingContinuation({ continuation in
            dealService?.getActualTransaction(dealId: state.deal.id, silent: true, completion: { result in
                continuation.resume(with: result)
            })
        })
    }

    private func getFinishTx() async throws -> ContractusAPI.Transaction {
        try await withCheckedThrowingContinuation({ continuation in
            dealService?.getTransaction(dealId: state.deal.id, silent: false, type: .dealFinish, completion: { result in
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
        guard let filePath = try? await downloadFile(url: file.url) else {
            debugPrint("downloadFile error");
            await MainActor.run {
                state.previewState = .none
                state.errorState = .error("Download file error")
            }
            return nil
        }

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
        guard let fileData = try? await Crypto.decrypt(encryptedData: fileEncryptedData, with: state.decryptedKey) else {
            debugPrint("Decrypt error");
            await MainActor.run {
                state.previewState = .none
                state.errorState = .error("Decrypt file error")
            }
            return nil
        }

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
            self.state.errorState = .error(error.localizedDescription)
            return nil
        }
    }

    private func checkLocalFiles() {
        state.deal.meta?.files.forEach { file in
            Task {
                let fileNameData = try? await Crypto.decrypt(base64Encrypted: file.name, with: state.decryptedKey)
                guard let fileNameData = fileNameData else { return }
                guard let fileName = String(data: fileNameData, encoding: .utf8) else { return }
                
                guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
                let folderURL = documentsURL.appendingPathComponent(file.url.lastPathComponent, isDirectory: true)
                let fileURL = folderURL.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    state.decryptedFiles[file.md5] = fileURL
                }
            }
        }
    }
    
    private func getDealActions(for deal: Deal, isSigned: Bool) -> [State.MainActionType] {
        let actions: [State.MainActionType]
        switch deal.status {
        case .new:
            if isSigned {
                actions = [.cancelSign]
            } else {
                actions = [.sign]
            }
        case .canceled, .unknown, .finished, .pending, .inProcessing:
            actions = []
        case .working:
            actions = [.finishDeal, .cancelDeal]
        }

        return actions
    }

    private func cancelSign() async throws {
        try await withCheckedThrowingContinuation({ (callback: CheckedContinuation<Void, Error>) in
            dealService?.cancelSignTransaction(dealId: state.deal.id, completion: { result in
                switch result {
                case .success:
                    callback.resume(returning: Void())
                case .failure(let error):
                    callback.resume(throwing: error)
                }
            })
        })
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
