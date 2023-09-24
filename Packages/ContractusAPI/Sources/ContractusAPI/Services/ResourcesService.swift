//
//  ResourcesService.swift
//  
//
//  Created by Simon Hudishkin on 17.08.2022.
//

import Foundation
import Alamofire

public final class ResourcesService: BaseService {

    public enum TokenListType {
        case full, `default`
    }
    
    public func tokens(type: TokenListType = .default, completion: @escaping (Swift.Result<[Token], APIClientError>) -> Void) {
        var data = [String:String]()
        if type == .full {
            data = ["type": "full"]
        }

        self.request(path: .tokens, httpMethod: .get, data: data) { (result: Swift.Result<[Token], APIClientError>) in
            completion(result)
        }
    }
}
