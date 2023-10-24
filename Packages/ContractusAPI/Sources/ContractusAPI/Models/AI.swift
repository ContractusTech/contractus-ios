import Foundation

public struct GeneratedText: Decodable {
    public let generated: String
}

public struct AIPrompt: Decodable {
    public let text: String
    public let tags: String?
}
