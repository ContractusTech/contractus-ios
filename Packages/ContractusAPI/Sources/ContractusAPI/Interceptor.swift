import Foundation
import Alamofire

public typealias VerifyDeviceAction = (@escaping (Result<AuthorizationHeader, Error>) -> Void) -> Void

class ContractusInterceptor: RequestInterceptor {
    var authorizationHeader: AuthorizationHeader?
    var performVerifyDevice: VerifyDeviceAction?

    init() { }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {

        var urlRequest = urlRequest
        if let authorizationHeader = authorizationHeader {
            urlRequest.headers.add(authorizationHeader.value)
        }
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            return completion(.doNotRetryWithError(error))
        }

        performVerifyDevice? { result in
            switch result {
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            case .success(let header):
                self.authorizationHeader = header
                completion(.retry)
            }
        }
    }
}
