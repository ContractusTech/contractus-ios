import Foundation
import Alamofire
import BigInt

public final class AIService: BaseService {

    struct TextGenerateRequest: Encodable {
        public let text: String
    }

    public func textGenerate(_ text: String, completion: @escaping (Swift.Result<GeneratedText, APIClientError>) -> Void) {
        self.request(path: .aiTextGenerate, httpMethod: .post, data: TextGenerateRequest(text: text)) { (result: Result<GeneratedText, APIClientError>) in
            completion(result)
        }
    }

    public func getPrompts(_ q: String? = "", completion: @escaping (Swift.Result<[AIPrompt], APIClientError>) -> Void) {
        self.request(path: .aiPrompts, httpMethod: .get, data: ["q": q]) { (result: Result<[AIPrompt], APIClientError>) in
            completion(result)
        }
    }
}
