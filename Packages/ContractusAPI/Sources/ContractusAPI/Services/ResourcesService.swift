//
//  ResourcesService.swift
//  
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import Foundation
import Alamofire

public final class ResourcesService: BaseService {

    public func availableCurrency(completion: @escaping (Swift.Result<[Currency], APIClientError>) -> Void) {
        self.request(path: .availableCurrencies, httpMethod: .get, data: Empty()) { (result: Swift.Result<[Currency], APIClientError>) in
            completion(result)
        }
    }


}
