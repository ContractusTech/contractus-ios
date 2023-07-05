import Foundation
import Alamofire

public class APIClient {
    let session: Session
    let server: ServerType
    private let interceptor: ContractusInterceptor

    public init(server: ServerType) {
        self.interceptor = ContractusInterceptor()

        self.session = Session(interceptor: self.interceptor)
        self.server = server
    }

    public func updateHeader(authorizationHeader: AuthorizationHeader? = nil) {
        interceptor.authorizationHeader = authorizationHeader
    }

    public func performVerifyDevice(_ action: @escaping VerifyDeviceAction) {
        interceptor.performVerifyDevice = action
    }
}

