import Foundation
import Alamofire
import BigInt

public final class ReferralService: BaseService {

    public struct CreatePromocode: Encodable {
        public let promocode: String
    }

    public func getInformation(completion: @escaping (Swift.Result<ReferralProgram, APIClientError>) -> Void) {
        self.request(path: .referral, httpMethod: .get, data: Empty()) { (result: Result<ReferralProgram, APIClientError>) in
            completion(result)
        }
    }

    public func createPromocode(completion: @escaping (Swift.Result<ReferralProgram, APIClientError>) -> Void) {
        self.request(path: .createPromocode, httpMethod: .post, data: Empty()) { (result: Result<ReferralProgram, APIClientError>) in
            completion(result)
        }
    }

    public func applyPromocode(_ data: CreatePromocode, completion: @escaping (Swift.Result<ReferralProgramResult, APIClientError>) -> Void) {
        self.request(path: .accountStatistics, httpMethod: .post, data: data) { (result: Result<ReferralProgramResult, APIClientError>) in
            completion(result)
        }
    }
}
