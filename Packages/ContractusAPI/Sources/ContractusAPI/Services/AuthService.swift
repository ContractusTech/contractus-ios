import Foundation
import Alamofire
import BigInt

public final class AuthService: BaseService {

    public struct VerifyDevice: Encodable {
        public let deviceToken: String
        public let identifier: String
        public let type: String = "IOS"

        public init(deviceToken: String, identifier: String) {
            self.deviceToken = deviceToken
            self.identifier = identifier
        }
    }

    public func verifyDevice(data: VerifyDevice, completion: @escaping (Swift.Result<DeviceMessage, APIClientError>) -> Void) {
        self.request(withAuth: false, path: .verifyDevice, httpMethod: .post, data: data) { (result: Result<DeviceMessage, APIClientError>) in
            completion(result)
        }
    }
}
