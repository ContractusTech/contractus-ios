//
//  AccountsService.swift
//  
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import Foundation
import Alamofire

public final class AccountService: BaseService {
    
    public func getAccount(completion: @escaping (Swift.Result<Account, APIClientError>) -> Void) {
        self.request(path: .accounts, httpMethod: .get, data: Empty()) { (result: Result<Account, APIClientError>) in
            completion(result)
        }
    }

    public func getBalance(completion: @escaping (Swift.Result<Balance, APIClientError>) -> Void) {
        self.request(path: .balance, httpMethod: .get, data: Empty()) { (result: Result<Balance, APIClientError>) in
            completion(result)
        }
    }
}
