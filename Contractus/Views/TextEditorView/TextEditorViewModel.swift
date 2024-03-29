//
//  TextViewerViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 19.08.2022.
//

import Foundation
import SolanaSwift
import ContractusAPI
import Combine

enum TextEditorInput {
    case decrypt
    case update(String, Bool)
    case dismissError
}

struct TextEditorState {

    enum ErrorState: Equatable {
        case error(String)
    }

    enum State: Equatable {
        case decrypting, updating, none, decrypted(String), needConfirmForce, success
    }
    let dealId: String
    let tier: Balance.Tier
    var content: DealMetadata

    var isDecrypted: Bool = false
    var state: State = .none
    var errorState: ErrorState?
    let contentType: DealsService.ContentType
}

final class TextEditorViewModel: ViewModel {

    @Published private(set) var state: TextEditorState
    private var cancelable = Set<AnyCancellable>()
    private let dealService: ContractusAPI.DealsService?
    private var encryptedContent: Data?
    private var startEditContent: Date?

    private let secretKey: Data

    internal init(
        dealId: String, 
        tier: Balance.Tier,
        content: DealMetadata,
        contentType: DealsService.ContentType,
        secretKey: Data,
        dealService: ContractusAPI.DealsService?
    ) {
        self.dealService = dealService
        self.state = TextEditorState(dealId: dealId, tier: tier, content: content, contentType: contentType)
        self.secretKey = secretKey
        self.startEditContent = Date()
    }

    func trigger(_ input: TextEditorInput, after: AfterTrigger? = nil) {
        switch input {
        case .dismissError:
            state.errorState = nil
            state.state = .none
        case .update(let value, let force):
            guard state.isDecrypted else { return }
            state.state = .updating
            if secretKey.isEmpty {
                preparingAndUpdateMetadata(text: value, force: force)
            } else {
                encryptAndUpdateMetadata(text: value, force: force)
            }
        case .decrypt:
            self.state.state = .decrypting
            guard let text = self.state.content.content?.text else {
                self.state.state = .decrypted("")
                self.state.isDecrypted = true
                return
            }
            if secretKey.isEmpty {
                if let text = text.fromBase64() {
                    self.state.isDecrypted = true
                    self.state.state = .decrypted(text)
                } else {
                    self.state.errorState = .error("Error")
                }
            } else {
                Crypto.decrypt(base64Encrypted: text, with: self.secretKey)
                    .receive(on: RunLoop.main)
                    .sink { result in
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            self.state.errorState = .error(error.localizedDescription)
                        }
                    } receiveValue: { data in
                        self.state.isDecrypted = true
                        self.state.state = .decrypted(String(data: data, encoding: .utf8) ?? "")
                    }.store(in: &cancelable)
            }
        }
    }

    private func encryptAndUpdateMetadata(text: String, force: Bool) {
        if text.isEmpty {
            let meta = DealMetadata(
                content: nil,
                files: self.state.content.files)
            self.updateMetadata(id: self.state.dealId, meta: meta, force: force)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        switch error as? ContractusAPI.APIClientError {
                        case .serviceError(let serviceError):
                            if serviceError.statusCode == 409 {
                                self.state.state = .needConfirmForce
                            } else {
                                fallthrough
                            }
                        default:
                            self.state.errorState = .error(error.localizedDescription)
                        }
                    case .finished:
                        self.state.state = .success
                    }
                } receiveValue: { result in
                    self.state.content = result
                }
                .store(in: &cancelable)
            return

        }

        Crypto.encrypt(message: text, with: secretKey)
            .flatMap({ encryptedData in
                Future<(String, String), Never> { promise in
                    let base64 = encryptedData.base64EncodedString()
                    promise(.success((base64, Crypto.md5(data: base64.data(using: .utf8)!))))
                }
            })
            .flatMap({ (text, md5) in
                let meta = DealMetadata(
                    content: TextContent(text: text, md5: md5),
                    files: self.state.content.files)
                return self.updateMetadata(id: self.state.dealId, meta: meta, force: force)
            })
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    switch error as? ContractusAPI.APIClientError {
                    case .serviceError(let serviceError):
                        if serviceError.statusCode == 409 {
                            self.state.state = .needConfirmForce
                        } else {
                            fallthrough
                        }
                    default:
                        self.state.errorState = .error(error.localizedDescription)
                    }
                case .finished:
                    self.state.state = .success
                }
            } receiveValue: { result in
                self.state.content = result
            }
            .store(in: &cancelable)
    }
    
    private func preparingAndUpdateMetadata(text: String, force: Bool) {
        Future<(String, String), Never> { promise in
            let base64 = Data(text.utf8).base64EncodedString()
            promise(.success((base64, Crypto.md5(data: base64.data(using: .utf8)!))))
        }
        .flatMap({ (text, md5) in
            let meta = DealMetadata(
                content: TextContent(text: text, md5: md5),
                files: self.state.content.files)
            return self.updateMetadata(id: self.state.dealId, meta: meta, force: force)
        })
        .receive(on: RunLoop.main)
        .sink { result in
            switch result {
            case .failure(let error):
                switch error as? ContractusAPI.APIClientError {
                case .serviceError(let serviceError):
                    if serviceError.statusCode == 409 {
                        self.state.state = .needConfirmForce
                    } else {
                        fallthrough
                    }
                default:
                    self.state.errorState = .error(error.localizedDescription)
                }

            case .finished:
                self.state.state = .success
            }

        } receiveValue: { result in
            self.state.content = result
        }
        .store(in: &cancelable)
    }

    private func updateMetadata(id: String, meta: DealMetadata, force: Bool) -> Future<DealMetadata, Error> {
        Future { promise in
            self.dealService?.update(dealId: id, typeContent: self.state.contentType, meta: UpdateDealMetadata(
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

}
