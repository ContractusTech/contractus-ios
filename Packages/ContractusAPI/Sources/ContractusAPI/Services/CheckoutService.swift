import Foundation
import Alamofire
import BigInt

public final class CheckoutService: BaseService {

    public struct CalculateRequest: Encodable {
        public let currencies: [String]
        public let amount: Double
        
        public init(amount: Double, currencies: [String] = []) {
            self.currencies = currencies
            self.amount = amount
        }
    }
    
    public struct CreateUrlRequest: Encodable {
        public enum CheckoutType: String, Encodable {
            case nowpayments
            case advcash
        }

        public let amount: Double
        public let blockchain: String
        public let publicKey: String
        public let type: CheckoutType

        public init(type: CheckoutType, amount: Double, blockchain: String, publicKey: String) {
            self.type = type
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

    public func available(completion: @escaping (Swift.Result<AvailableMethodsResult, APIClientError>) -> Void) {
        self.request(path: .available, httpMethod: .get, data: Empty()) { (result: Result<AvailableMethodsResult, APIClientError>) in
            completion(result)
        }
    }

    public func create(_ data: CreateUrlRequest, completion: @escaping (Swift.Result<CreateUrlResult, APIClientError>) -> Void) {
        self.request(path: .create, httpMethod: .post, data: data) { (result: Result<CreateUrlResult, APIClientError>) in
            completion(result)
        }
    }
}
