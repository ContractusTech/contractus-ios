//
//  AccountsService.swift
//  
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import Foundation
import Alamofire
import BigInt

public final class AccountService: BaseService {

    public struct Pagination: Encodable {
        public let skip: Int
        public let take: Int
        public let q: String?
    }

    public struct Token: Codable {

        public let code: String
        public let address: String?

        public init(code: String, address: String?) {
            self.code = code
            self.address = address
        }
    }

    public struct BalanceRequest: Codable {

        public enum Currency: String, Codable {
            case usd = "USD"
        }

        public let tokens: [Token]
        public let currency: Currency

        public init(tokens: [AccountService.Token], currency: AccountService.BalanceRequest.Currency = .usd) {
            self.tokens = tokens
            self.currency = currency
        }
    }

    public struct SignedTransaction: Codable {

        public let id: String
        public let transaction: String
        public let signature: String

        public init(id: String, transaction: String, signature: String) {
            self.id = id
            self.transaction = transaction
            self.signature = signature
        }
    }
    
    public func getAccount(completion: @escaping (Swift.Result<Account, APIClientError>) -> Void) {
        self.request(path: .currentAccount, httpMethod: .get, data: Empty()) { (result: Result<Account, APIClientError>) in
            completion(result)
        }
    }

    public func getAccounts(params: Pagination, completion: @escaping (Swift.Result<[Account], APIClientError>) -> Void) {
        self.request(path: .currentAccount, httpMethod: .get, data: params) { (result: Result<[Account], APIClientError>) in
            completion(result)
        }
    }

    public func getBalance(_ request: BalanceRequest, completion: @escaping (Swift.Result<Balance, APIClientError>) -> Void) {
        self.request(path: .balance, httpMethod: .post, data: request) { (result: Result<Balance, APIClientError>) in
            completion(result)
        }
    }

    public func wrap(_ amount: Amount, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .wrap, httpMethod: .post, data: amount) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func signWrap(_ request: SignedTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .signWrap, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func unwrapAll(completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .unwrap, httpMethod: .post, data: Empty()) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func signUnwrapAll(_ request: SignedTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .signUnwrap, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }
}
