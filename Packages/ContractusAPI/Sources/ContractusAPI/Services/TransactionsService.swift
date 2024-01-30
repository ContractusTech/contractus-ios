//
//  TransactionService.swift
//  
//
//  Created by Simon Hudishkin on 18.04.2023.
//

import Foundation
import BigInt

public final class TransactionsService: BaseService {

    public struct SignedWrapTransaction: Codable {

        public let id: String
        public let transaction: String
        public let signature: String

        public init(id: String, transaction: String, signature: String) {
            self.id = id
            self.transaction = transaction
            self.signature = signature
        }
    }

    public struct Pagination: Encodable {
        public let dealId: String?
        public let skip: Int
        public let take: Int
        public let types: Set<DealsService.FilterByRole>
        public let statuses: Set<DealsService.FilterByStatus>

        public init(dealId: String? = nil, skip: Int, take: Int, types: Set<DealsService.FilterByRole>, statuses: Set<DealsService.FilterByStatus>) {
            self.skip = skip
            self.dealId = dealId
            self.take = take
            self.types = types
            self.statuses = statuses
        }
    }
    
    public struct TransferTransaction: Codable {
        public let value: BigUInt
        public let token: AccountService.Token
        public let recipient: String
        
        public init(value: BigUInt, token: AccountService.Token, recipient: String) {
            self.value = value
            self.token = token
            self.recipient = recipient
        }
        
        enum CodingKeys: CodingKey {
            case value
            case token
            case recipient
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value.description, forKey: .value)
            try container.encode(token, forKey: .token)
            try container.encode(recipient, forKey: .recipient)
        }
    }

    public func getTransactions(pagination: TransactionsService.Pagination, completion: @escaping (Swift.Result<[Transaction], APIClientError>) -> Void) {
        self.request(path: .transactions, httpMethod: .get, data: pagination) { (result: Swift.Result<[Transaction], APIClientError>) in
            completion(result)
        }
    }

    public func getTransaction(id: String, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .transaction(id), httpMethod: .get, data: Empty()) { (result: Swift.Result<Transaction, APIClientError>) in
            completion(result)
        }
    }


    public func wrap(_ amount: AmountValue, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .wrap, httpMethod: .post, data: amount) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func signWrap(_ request: SignedWrapTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .signWrap, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func unwrapAll(completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .unwrap, httpMethod: .post, data: Empty()) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func signUnwrapAll(_ request: SignedWrapTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .signUnwrap, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }
    
    public func transfer(_ request: TransferTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .transfer, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func transferSign(_ request: SignedWrapTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .transferSign, httpMethod: .post, data: request) { (result: Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func getApprovalAmountTransaction(for tokenAddress: String?, completion: @escaping (Swift.Result<ApprovalAmount, APIClientError>) -> Void) {
        self.request(path: .approvalAmount(address: tokenAddress ?? "service"), httpMethod: .get, data: Empty()) { (result: Result<ApprovalAmount, APIClientError>) in
            completion(result)
        }
    }

    public func approveAmountTransaction(_ tx: ApprovalSignedTransaction, completion: @escaping (Swift.Result<TransactionResult, APIClientError>) -> Void) {
        self.request(path: .approveAmount, httpMethod: .post, data: tx) { (result: Result<TransactionResult, APIClientError>) in
            completion(result)
        }
    }

    public func getExternalTransaction(_ signature: String, completion: @escaping (Swift.Result<ExternalTransaction, APIClientError>) -> Void) {
        self.request(path: .checkExternalTx(signature: signature), httpMethod: .get, data: Empty()) { (result: Result<ExternalTransaction, APIClientError>) in
            completion(result)
        }
    }
}
