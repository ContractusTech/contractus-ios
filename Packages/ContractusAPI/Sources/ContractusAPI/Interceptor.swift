import Foundation
import Alamofire

public typealias VerifyDeviceAction = (@escaping (Result<AuthorizationHeader, Error>) -> Void) -> Void
public typealias BlockedAuthorizationAction = (Error) -> Void

struct OAuthCredential: AuthenticationCredential {
    let value: HTTPHeader
    let expiredAt: Date
    var requiresRefresh: Bool { expiredAt < Date() }
}

final class OAuthAuthenticator: Authenticator {

    var performVerifyDevice: VerifyDeviceAction?
    var blockedAuthorization: BlockedAuthorizationAction?

    func apply(_ credential: OAuthCredential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(credential.value)
    }

    func refresh(_ credential: OAuthCredential,
                 for session: Session,
                 completion: @escaping (Result<OAuthCredential, Error>) -> Void) {

        performVerifyDevice? { result in
            switch result {
            case .failure(let error):
                if error.asAFError?.responseCode == 423 {
                    self.blockedHandler()
                }
                completion(.failure(error))
            case .success(let header):
                completion(.success(.init(value: header.value, expiredAt: header.expiredAt)))
            }
        }
    }

    func didRequest(_ urlRequest: URLRequest,
                    with response: HTTPURLResponse,
                    failDueToAuthenticationError error: Error) -> Bool {
        if response.statusCode == 423 {
            self.blockedHandler()
        }
        return response.statusCode == 401
    }

    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: OAuthCredential) -> Bool {
        return urlRequest.headers[credential.value.name] == credential.value.value
    }

    private func blockedHandler() {
        self.blockedAuthorization?(APIClientError.serviceError(.init(statusCode: 423, error: "Device is invalid or blocked.")))
    }
}
