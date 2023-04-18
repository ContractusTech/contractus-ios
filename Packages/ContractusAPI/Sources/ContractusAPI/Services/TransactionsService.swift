//
//  TransactionService.swift
//  
//
//  Created by Simon Hudishkin on 18.04.2023.
//

import Foundation

public final class TransactionsService: BaseService {

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
}
