import Foundation
import Alamofire

public typealias VerifyDeviceAction = (@escaping (Result<AuthorizationHeader, Error>) -> Void) -> Void
public typealias BlockedAuthorizationAction = (Error) -> Void

class ContractusInterceptor: RequestInterceptor {
    var authorizationHeader: AuthorizationHeader?
    var performVerifyDevice: VerifyDeviceAction?
    var blockedAuthorization: BlockedAuthorizationAction?

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
            if error.asAFError?.responseCode == 423 {
                self.blockedAuthorization?(APIClientError.serviceError(.init(statusCode: 423, error: "Device is invalid or blocked.")))
            }
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

    private func parseError(data: Data?) -> APIClientError? {
        if let data = data, let error = try? JSONDecoder().decode(ServiceError.self, from: data) {
            return APIClientError.serviceError(error)
        }
        return nil
    }
}
