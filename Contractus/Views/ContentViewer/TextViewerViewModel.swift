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

enum TextViewerInput {
    case decrypt
    case update(String)
}

struct TextViewerState {
    enum State {
        case decrypting, updating, none, error
    }
    let encryptedContent: TextContent
    var decryptedText: String = ""
    var isDecryped: Bool = false
    var errorMessage: String = ""
    var state: State = .none

}

final class TextViewerViewModel: ViewModel {

    let decryptedKey: Data
    @Published private(set) var state: TextViewerState
    private var bag = Set<AnyCancellable>()

    internal init(decryptedKey: Data, state: TextViewerState) {
        self.decryptedKey = decryptedKey
        self.state = state
    }

    func trigger(_ input: TextViewerInput, after: AfterTrigger? = nil) {
        switch input {
        case .decrypt:
            self.state.state = .decrypting
            guard let data = Data(base64Encoded: state.encryptedContent.text) else { return }
            Crypto.decrypt(encryptedData: data, with: decryptedKey)
                .receive(on:RunLoop.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        self.state.isDecryped = false
                        self.state.errorMessage = error.localizedDescription
                        self.state.state = .error
                    case .finished:
                        self.state.errorMessage = ""
                    }
                } receiveValue: { data in
                    self.state.decryptedText = String(data: data, encoding: .utf8)!
                    self.state.isDecryped = true
                    self.state.state = .none
                }.store(in: &bag)
        case .update(let value):
            self.state.state = .updating


        }
    }

}
