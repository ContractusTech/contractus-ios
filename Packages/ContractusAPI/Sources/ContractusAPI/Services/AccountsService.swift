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

    public func getStatistics(_ currencyCode: String, completion: @escaping (Swift.Result<[AccountStatistic], APIClientError>) -> Void) {
        self.request(path: .accountStatistics, httpMethod: .get, data: [ "currency": currencyCode ]) { (result: Result<[AccountStatistic], APIClientError>) in
            completion(result)
        }
    }

    public func getBalance(_ request: BalanceRequest, completion: @escaping (Swift.Result<Balance, APIClientError>) -> Void) {
        self.request(path: .balance, httpMethod: .post, data: request) { (result: Result<Balance, APIClientError>) in
            completion(result)
        }
    }

    public func getTopUpMethods(completion: @escaping (Swift.Result<TopUpMethods, APIClientError>) -> Void) {
        self.request(path: .topUp, httpMethod: .post, data: Empty()) { (result: Result<TopUpMethods, APIClientError>) in
            completion(result)
        }
    }
}
