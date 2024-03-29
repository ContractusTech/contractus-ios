import Foundation
import SolanaSwift
import ContractusAPI
import Combine

final class TextGenViewModel: ViewModel {

    enum Input {
        case generate(String)
    }

    struct State {

        enum State {
            case none, loading, loaded
        }

        var prompts: [AIPrompt] = []
        var state: State = .none
        var generatedText: String = ""
    }

    private let aiService: ContractusAPI.AIService

    @Published private(set) var state: State

    init(aiService: ContractusAPI.AIService) {
        self.aiService = aiService
        self.state = .init()

        Task { @MainActor in
            self.state.prompts = (try? await loadPrompts()) ?? []
        }
    }

    func trigger(_ input: Input, after: AfterTrigger?) {
        switch input {
        case .generate(let text):
            state.state = .loading
            Task { @MainActor in

                let text = (try? await generate(text: text))?.generated ?? ""
                state.generatedText = text
                state.state = .loaded
            }
        }
    }

    private func generate(text: String) async throws -> GeneratedText {
        try await withCheckedThrowingContinuation { continuation in
            aiService.textGenerate(text) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func loadPrompts() async throws -> [AIPrompt] {
        try await withCheckedThrowingContinuation { continuation in
            aiService.getPrompts(completion: { result in
                continuation.resume(with: result)
            })
        }
    }
}

extension AIPrompt: Identifiable {
    public var id: String {
        return "\(self)"
    }
}
