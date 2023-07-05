import Foundation
import Alamofire
import BigInt

public final class AuthService: BaseService {

    struct VerifyDevice: Encodable {
        let deviceId: String
        let type: String = "IOS"
    }

    public func verifyDevice(deviceId: String, completion: @escaping (Swift.Result<DeviceMessage, APIClientError>) -> Void) {
        self.request(path: .verifyDevice, httpMethod: .post, data: VerifyDevice(deviceId: deviceId)) { (result: Result<DeviceMessage, APIClientError>) in
            completion(result)
        }
    }
}
