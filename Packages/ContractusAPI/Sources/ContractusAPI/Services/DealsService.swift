//
//  DealsService.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import Alamofire

public final class DealsService: BaseService {

    public struct Pagination: Encodable {
        public let skip: Int
        public let take: Int
        public let types: Set<FilterByRole>
        public let statuses: Set<FilterByStatus>

        public init(skip: Int, take: Int, types: Set<DealsService.FilterByRole>, statuses: Set<DealsService.FilterByStatus>) {
            self.skip = skip
            self.take = take
            self.types = types
            self.statuses = statuses
        }
    }

    public enum FilterByRole: String, Encodable {
        case isClient = "CLIENT", isExecutor = "EXECUTOR", isChecker = "CHECKER"
    }

    public enum FilterByStatus: String, Encodable {
        case new = "NEW", starting = "STARTING", started = "STARTED", finished = "FINISHED", finishing = "FINISHING", canceled = "CANCELED", canceling = "CANCELING"
    }

    public enum ContentType {
        case metadata, result
    }

    public func getDeals(pagination: DealsService.Pagination, completion: @escaping (Swift.Result<[Deal], APIClientError>) -> Void) {
        self.request(path: .deals, httpMethod: .get, data: pagination) { (result: Swift.Result<[Deal], APIClientError>) in
            completion(result)
        }
    }

    public func getDeal(id: String, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .deal(id), httpMethod: .get, data: Empty()) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func create(data: NewDeal, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
            self.request(path: .deals, httpMethod: .post, data: data) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func addParticipate(to dealId: String, data: NewParticipate, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
            self.request(path: .participant(dealId), httpMethod: .post, data: data) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func deleteParticipate(from dealId: String, type: ParticipateType, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .participant(dealId), httpMethod: .delete, data: ["type": type]) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func update(dealId: String, data: UpdateDeal, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .deal(dealId), httpMethod: .post, data: data) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func actions(dealId: String, completion: @escaping (Swift.Result<DealAction, APIClientError>) -> Void) {
        self.request(path: .dealAction(dealId), httpMethod: .get, data: Empty()) { (result: Swift.Result<DealAction, APIClientError>) in
            completion(result)
        }
    }

    public func update(dealId: String, typeContent: ContentType, meta: UpdateDealMetadata, completion: @escaping (Swift.Result<DealMetadata, APIClientError>) -> Void) {
        switch typeContent {
        case .metadata:
            self.request(path: .dealMetadata(dealId), httpMethod: .post, data: meta) { (result: Swift.Result<DealMetadata, APIClientError>) in
                completion(result)
            }
        case .result:
            let result = UpdateDealResults(
                result: meta.meta,
                updatedAt: meta.updatedAt,
                force: meta.force
            )
            self.request(path: .dealResult(dealId), httpMethod: .post, data: result) { (result: Swift.Result<DealMetadata, APIClientError>) in
                completion(result)
            }
        }
    }

    public func cancel(dealId: String, force: Bool, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .cancelDeal(dealId), httpMethod: .post, data: CancelDeal(force: force)) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func transactions(dealId: String, completion: @escaping (Swift.Result<[Transaction], APIClientError>) -> Void) {
        self.request(path: .dealTransactions(dealId), httpMethod: .get, data: Empty()) { (result: Swift.Result<[Transaction], APIClientError>) in
            completion(result)
        }
    }

    public func getTransaction(dealId: String, silent: Bool, type: TransactionType, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .dealTransaction(dealId, type), httpMethod: .get, data: ["silent": silent ? 1 : 0]) { (result: Swift.Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func signTransaction(dealId: String, type: TransactionType, data: SignedTransaction, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        self.request(path: .dealSign(dealId, type), httpMethod: .post, data: data) { (result: Swift.Result<Transaction, APIClientError>) in
            completion(result)
        }
    }

    public func cancelSignTransaction(dealId: String, completion: @escaping (Swift.Result<Success, APIClientError>) -> Void) {
        self.request(path: .dealSign(dealId, .dealInit), httpMethod: .delete, data: Empty()) { (result: Swift.Result<Success, APIClientError>) in
            completion(result)
        }
    }

    public func getActualTransaction(dealId: String, silent: Bool, completion: @escaping (Swift.Result<Transaction, APIClientError>) -> Void) {
        transactions(dealId: dealId) { result in
            switch result {
            case .success(let txList):
                var type: TransactionType = .dealInit
                if txList.isEmpty {
                    type = .dealInit
                } else {
                    let newTxs = txList.filter { $0.status == .new }
                    if newTxs.count == 1 && !newTxs[0].transaction.isEmpty {
                        return completion(.success(txList[0]))
                    }
                    
                }

                // TODO: - Не доделано, надо добавить определение других типов транзакций (cancel, finish)

                self.getTransaction(dealId: dealId, silent: silent, type: type) { result in
                    switch result {
                    case .success(let tx):
                        completion(.success(tx))
                    case .failure(let failure):
                        completion(.failure(failure))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func getFee(dealId: String, data: CalculateDealFee, completion: @escaping (Swift.Result<DealFee, APIClientError>) -> Void) {
        self.request(path: .dealFee(dealId: dealId), httpMethod: .post, data: data) { (result: Swift.Result<DealFee, APIClientError>) in
            completion(result)
        }
    }
}
