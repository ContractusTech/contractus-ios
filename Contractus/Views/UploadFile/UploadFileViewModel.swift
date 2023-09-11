//
//  UploadFileViewModel.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import Foundation
import ContractusAPI
import SolanaSwift
import SwiftUI
import Combine

enum UploadFileInput {
    case selected(RawFile), uploadAndUpdate, clear, updateForce
}

struct UploadFileResult: Equatable {
    let file: UploadedFile
    let sourceName: String
    let encryptedName: String
}

struct UploadFileState {
    enum State: Equatable {
        case none, selected, selectedNoKey, encrypting, uploading(Int), saving, success(DealMetadata), error(String), needConfirmForce
    }
    let dealId: String
    var content: DealMetadata
    var selectedFile: RawFile?
    var state: State = .none
    let contentType: DealsService.ContentType

}

final class UploadFileViewModel: ViewModel {

    @Published var state: UploadFileState

    private var dealService: ContractusAPI.DealsService?
    private var filesAPIService: ContractusAPI.FilesService?
    private var cancelable = Set<AnyCancellable>()
    private var startEditContent = Date()
    private(set) var encryptedFile: UploadFileResult?
    private var unsavedMetadata: DealMetadata?

    private let secretKey: Data

    init(
        dealId: String,
        content: DealMetadata,
        contentType: DealsService.ContentType,
        secretKey: Data,
        dealService: ContractusAPI.DealsService?,
        filesAPIService: ContractusAPI.FilesService?)
    {
        self.dealService = dealService
        self.state = UploadFileState(dealId: dealId, content: content, contentType: contentType)
        self.filesAPIService = filesAPIService
        self.secretKey = secretKey
    }

    func trigger(_ input: UploadFileInput, after: AfterTrigger? = nil) {

        switch input {
        case.selected(let file):
            self.state.selectedFile = file
            self.state.state = secretKey.isEmpty ? .selectedNoKey : .selected
        case .clear:
            self.state.selectedFile = nil
            self.state.state = .none
        case .updateForce:
            guard let metadata = unsavedMetadata else { return }
            self.updateMetadata(id: self.state.dealId, meta: metadata, force: true)
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        self.state.state = .error(error.localizedDescription)
                    case .finished:
                        break
                    }
                } receiveValue: { meta in
                    self.unsavedMetadata = nil
                    self.state.state = .success(meta)
                }.store(in: &cancelable)

        case .uploadAndUpdate:
            guard let file = self.state.selectedFile else { return }
            guard !self.secretKey.isEmpty else {
                uploadFile(file: file)
                return
            }
            encryptAndUploadFile(file: file)


// TODO: - Нужно подумать как отменять шифрование
//        case .cancel:
        }

    }
}

fileprivate extension UploadFileViewModel {
    func upload(file: UploadFile) -> Future<UploadedFile, Error> {
        DispatchQueue.main.async {
            self.state.state = .uploading(0)
        }
        return Future { promise in
            self.filesAPIService?.upload(data: file, progressCallback: {[weak self] fraction in
                DispatchQueue.main.async {
                    self?.state.state = .uploading(Int(fraction * 100))
                }
            }, completion: { result in
                switch result {
                case .success(let file):
                    promise(.success(file))
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                    promise(.failure(error as Error))
                }
            })
        }
    }
    
    private func uploadFile(file: RawFile) {
        Future<(UploadFile, String), Never> { promise in
            promise(.success((UploadFile(
                md5: Crypto.md5(data: file.data),
                data: file.data,
                fileName: UUID().uuidString,
                mimeType: DEFAULT_MIME_TYPE), file.name)))
        }
        .eraseToAnyPublisher()
        .flatMap({ file, name in
            self.upload(file: file).eraseToAnyPublisher()
                .flatMap { file -> AnyPublisher<UploadFileResult, Never> in
                    Future<UploadFileResult, Never> { promise in
                        promise(.success(UploadFileResult(
                            file: file,
                            sourceName: self.state.selectedFile?.name ?? "",
                            encryptedName: name)
                        ))
                    }
                    .eraseToAnyPublisher()
                }
        })
        .eraseToAnyPublisher()
        .receive(on: RunLoop.main)
        .sink { result in
            switch result {
            case .failure(let error):
                debugPrint(error.localizedDescription)
                self.state.state = .error(error.localizedDescription)
            case .finished: break
            }
        } receiveValue: { encryptedFile in
            self.encryptedFile = encryptedFile
            self.preparingAndUpdateMetadata()
        }.store(in: &cancelable)
    }

    private func encryptAndUploadFile(file: RawFile) {
        self.state.state = .encrypting
        Crypto
            .encrypt(message: file.name, with: secretKey)
            .flatMap({ data in
                Future<String, Never> { promise in
                    promise(.success(data.base64EncodedString()))
                }
            })
            .flatMap({ fileName -> AnyPublisher<(String, Data), Error> in
                Crypto.encrypt(data: file.data, with: self.secretKey)
                    .flatMap { data in
                        Future<(String, Data), Error> { promise in
                            promise(.success((fileName, data)))
                        }
                    }.eraseToAnyPublisher()
            })
            .flatMap({ result in
                Future<(UploadFile, String), Never> { promise in
                    promise(.success((UploadFile(
                        md5: Crypto.md5(data: result.1),
                        data: result.1,
                        fileName: UUID().uuidString,
                        mimeType: DEFAULT_MIME_TYPE), result.0)))
                }.eraseToAnyPublisher()
            })
            .flatMap({ file, encryptedName in
                self.upload(file: file).eraseToAnyPublisher()
                    .flatMap { file -> AnyPublisher<UploadFileResult, Never> in
                        Future<UploadFileResult, Never> { promise in
                            promise(.success(UploadFileResult(
                                file: file,
                                sourceName: self.state.selectedFile?.name ?? "",
                                encryptedName: encryptedName)))
                        }.eraseToAnyPublisher()
                    }
            })
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                    self.state.state = .error(error.localizedDescription)
                case .finished: break
                }
            } receiveValue: { encryptedFile in
                self.encryptedFile = encryptedFile
                self.preparingAndUpdateMetadata()
            }.store(in: &cancelable)
    }

    private func preparingAndUpdateMetadata() {
        self.state.state = .saving
        var files = state.content.files
        if let file = encryptedFile {
            files.append(.init(md5: file.file.md5, url: file.file.url, name: file.encryptedName, encrypted: true, size: file.file.size))
        }

        let meta = DealMetadata(content: state.content.content, files: files)
        self.updateMetadata(id: self.state.dealId, meta: meta, force: false)
            .receive(on: RunLoop.main)
            .sink { result in
                switch result {
                case .failure(let error):
                    switch error as? ContractusAPI.APIClientError {
                    case .serviceError(let serviceError):
                        if serviceError.statusCode == 409 {
                            self.unsavedMetadata = meta
                            self.state.state = .needConfirmForce
                        } else {
                            fallthrough
                        }

                    default:
                        self.state.state = .error(error.localizedDescription)
                    }
                case .finished:
                    break
                }

            } receiveValue: { meta in
                self.state.content = meta
                self.state.state = .success(meta)
            }
            .store(in: &cancelable)
    }

    private func updateMetadata(id: String, meta: DealMetadata, force: Bool) -> Future<DealMetadata, Error> {
        Future { promise in
            self.dealService?.update(dealId: id, typeContent: self.state.contentType, meta: UpdateDealMetadata(
                meta: meta,
                updatedAt: self.startEditContent,
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
