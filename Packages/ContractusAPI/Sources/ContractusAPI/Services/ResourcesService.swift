//
//  ResourcesService.swift
//  
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import Foundation
import Alamofire

public final class ResourcesService: BaseService {

    public func tokens(completion: @escaping (Swift.Result<[Token], APIClientError>) -> Void) {
        self.request(path: .tokens, httpMethod: .get, data: ["type": "full"]) { (result: Swift.Result<[Token], APIClientError>) in
            completion(result)
        }
    }
}
