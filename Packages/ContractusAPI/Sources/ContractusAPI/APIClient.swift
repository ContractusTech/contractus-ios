import Foundation
import Alamofire

public class APIClient {
    let session: Session
    public let server: ServerType

    private var interceptor: AuthenticationInterceptor<OAuthAuthenticator>
    private var authenticator = OAuthAuthenticator()

    public var hasHeader: Bool {
        interceptor.credential != nil
    }

    public init(server: ServerType) {
        self.authenticator = OAuthAuthenticator()

        self.interceptor = AuthenticationInterceptor(
            authenticator: authenticator,
            credential: nil)
        self.session = Session(interceptor: interceptor)
        self.server = server

    }

    public func updateHeader(authorizationHeader: AuthorizationHeader? = nil) {
        if let authorizationHeader = authorizationHeader {
            interceptor.credential = .init(value: authorizationHeader.value, expiredAt: authorizationHeader.expiredAt)
        } else {
            interceptor.credential =  nil
        }

    }

    public func performVerifyDevice(_ action: @escaping VerifyDeviceAction) {
        authenticator.performVerifyDevice = action
    }

    public func setBlockedAuthorizationHandler(_ action: BlockedAuthorizationAction?) {
        authenticator.blockedAuthorization = action
    }
}

