import Foundation
import Alamofire
import BigInt

public final class CheckoutService: BaseService {

    public struct CalculateRequest: Encodable {
        public let currencies: [String]
        public let amount: Double
        
        public init(amount: Double) {
            self.currencies = []
            self.amount = amount
        }
    }
    
    public struct CreateUrlRequest: Encodable {
        public let amount: Double
        public let blockchain: String
        public let publicKey: String
        
        public init(amount: Double, blockchain: String, publicKey: String) {
            self.amount = amount
            self.blockchain = blockchain
            self.publicKey = publicKey
        }
    }

    public func calculate(_ data: CalculateRequest, completion: @escaping (Swift.Result<CalculateResult, APIClientError>) -> Void) {
        self.request(path: .calculate, httpMethod: .post, data: data) { (result: Result<CalculateResult, APIClientError>) in
            completion(result)
        }
    }

    public func create(_ data: CreateUrlRequest, completion: @escaping (Swift.Result<CreateUrlResult, APIClientError>) -> Void) {
        self.request(path: .create, httpMethod: .post, data: data) { (result: Result<CreateUrlResult, APIClientError>) in
            completion(result)
        }
    }
}
