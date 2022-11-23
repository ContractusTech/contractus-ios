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
}

struct TextEditorState {
    enum State: Equatable {
        case decrypting, updating, none, decrypted(String), error(String), needConfirmForce, success
    }
    let dealId: String
    var content: DealMetadata

    var isDecrypted: Bool = false
    var state: State = .none
    let contentType: DealsService.ContentType
}

final class TextEditorViewModel: ViewModel {

    @Published private(set) var state: TextEditorState
    private var cancelable = Set<AnyCancellable>()
    private let dealService: ContractusAPI.DealsService?
    private var encryptedContent: Data?
    private var startEditContent: Date?

    private let secretKey: Data

    internal init(dealId: String, content: DealMetadata, contentType: DealsService.ContentType, secretKey: Data, dealService: ContractusAPI.DealsService?) {
        self.dealService = dealService
        self.state = TextEditorState(dealId: dealId, content: content, contentType: contentType)
        self.secretKey = secretKey
    }

    func trigger(_ input: TextEditorInput, after: AfterTrigger? = nil) {
        switch input {
        case .update(let value, let force):
            guard state.isDecrypted else { return }
            state.state = .updating
            preparingAndUpdateMetadata(text: value, force: force)

        case .decrypt:
            self.state.state = .decrypting
            guard let text = self.state.content.content?.text else {
                self.state.state = .decrypted("")
                self.state.isDecrypted = true
                return
            }
            startEditContent = Date()
            Crypto.decrypt(base64Encrypted: text, with: self.secretKey)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.state.state = .error(error.localizedDescription)
                    }
                } receiveValue: { data in
                    self.state.isDecrypted = true
                    self.state.state = .decrypted(String(data: data, encoding: .utf8) ?? "")
                }.store(in: &cancelable)
        }
    }

    private func preparingAndUpdateMetadata(text: String, force: Bool) {
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
                        self.state.state = .error(error.localizedDescription)
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
