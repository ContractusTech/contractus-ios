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
    case selected(RawFile), upload, clear //, cancel
}

struct UploadFileResult {
    let file: UploadedFile
    let sourceName: String
    let encryptedName: String
}

struct UploadFileState {
    enum State {
        case none, selected(String), encrypting, uploading(Int), error, success(UploadFileResult)
    }
    var account: SolanaSwift.Account
    var state: State = .none
}

final class UploadFileViewModel: ViewModel {

    @Published var state: UploadFileState

    private var selectedFile: RawFile?
    private var uploadedFile: UploadFileResult?
    private var filesAPIService: ContractusAPI.FilesService?
    private var cancelable = Set<AnyCancellable>()

    init(
        account: SolanaSwift.Account,
        filesAPIService: ContractusAPI.FilesService?)
    {
        self.state = UploadFileState(account: account)
        self.filesAPIService = filesAPIService
    }

    func trigger(_ input: UploadFileInput, after: AfterTrigger? = nil) {

        switch input {
        case.selected(let file):
            self.selectedFile = file
            self.state.state = .selected(file.name)
        case .clear:
            self.selectedFile = nil
            self.state.state = .none
        case .upload:
            guard let file = self.selectedFile else { return }

            self.state.state = .encrypting
            Crypto
                .encrypt(message: file.name, with: state.account.secretKey)
                .flatMap({ data in
                    Future<String, Never> { promise in
                        promise(.success(data.base64EncodedString()))
                    }
                })
                .flatMap({ fileName -> AnyPublisher<(String, Data), Error> in
                    Crypto.encrypt(data: file.data, with: self.state.account.secretKey)
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
                                    sourceName: self.selectedFile?.name ?? "",
                                    encryptedName: encryptedName)))
                            }.eraseToAnyPublisher()
                        }
                })
                .eraseToAnyPublisher()
                .handleEvents(receiveCancel: {
                    self.state.state = .none

                })
                .receive(on: RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        debugPrint(error.localizedDescription)
                        self.state.state = .error
                    case .finished: break
                    }
                } receiveValue: { uploadedFile in
                    self.state.state = .success(uploadedFile)
                }.store(in: &cancelable)
// Нужно подумать как отменять шифрование
//        case .cancel:
//            cancelable.forEach({ $0.cancel() })
//            guard let selectedFile = selectedFile else { return }
//            state.state = .selected(selectedFile.name)
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
                self?.state.state = .uploading(Int(fraction * 100))
                debugPrint(Int(fraction * 100))
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
}
