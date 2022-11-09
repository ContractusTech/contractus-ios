//
//  File.swift
//  
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import Foundation
import Alamofire

public class APIClient {

    let session: Session
    let server: ServerType
    private let interceptor: ContractusInterceptor

    public init(server: ServerType, authorizationHeader: AuthorizationHeader? = nil) {
        self.interceptor = ContractusInterceptor(authorizationHeader: authorizationHeader)
        self.session = Session(interceptor: self.interceptor)
        self.server = server
    }

    public func updateHeader(authorizationHeader: AuthorizationHeader? = nil) {
        interceptor.authorizationHeader = authorizationHeader
    }
}

class ContractusInterceptor: RequestInterceptor {

    var authorizationHeader: AuthorizationHeader?

    init(authorizationHeader: AuthorizationHeader?) {
        self.authorizationHeader = authorizationHeader
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {

        var urlRequest = urlRequest
        if let authorizationHeader = authorizationHeader {
            urlRequest.headers.add(authorizationHeader.value)
        }
        completion(.success(urlRequest))
    }
}
