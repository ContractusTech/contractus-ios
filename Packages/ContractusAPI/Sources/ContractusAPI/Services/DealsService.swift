//
//  DealsService.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import Alamofire

public final class DealsService: BaseService {

    public enum ContentType {
        case metadata, result
    }

    public func getDeals(pagination: Pagination, completion: @escaping (Swift.Result<[Deal], APIClientError>) -> Void) {
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

    public func update(dealId: String, data: UpdateAmountDeal, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .deal(dealId), httpMethod: .post, data: data) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func update(dealId: String, typeContent: ContentType, meta: UpdateDealMetadata, completion: @escaping (Swift.Result<DealMetadata, APIClientError>) -> Void) {
        let path: ServicePath

        switch typeContent {
        case .metadata:
            path = .dealMetadata(dealId)
        case .result:
            path = .dealResult(dealId)
        }
        self.request(path: path, httpMethod: .post, data: meta) { (result: Swift.Result<DealMetadata, APIClientError>) in
            completion(result)
        }
    }

    public func cancel(dealId: String, force: Bool, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .cancelDeal(dealId), httpMethod: .post, data: CancelDeal(force: force)) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func transactions(dealId: String, completion: @escaping (Swift.Result<[DealTransaction], APIClientError>) -> Void) {
        self.request(path: .dealTransactions(dealId), httpMethod: .get, data: Empty()) { (result: Swift.Result<[DealTransaction], APIClientError>) in
            completion(result)
        }
    }

    public func getTransaction(dealId: String, silent: Bool, type: TransactionType, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
        self.request(path: .dealTransaction(dealId, type), httpMethod: .get, data: ["silent": silent ? 1 : 0]) { (result: Swift.Result<DealTransaction, APIClientError>) in
            completion(result)
        }
    }

    public func signTransaction(dealId: String, type: TransactionType, data: SignedDealTransaction, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
        self.request(path: .dealSign(dealId, type), httpMethod: .post, data: data) { (result: Swift.Result<DealTransaction, APIClientError>) in
            completion(result)
        }
    }

    public func getActualTransaction(dealId: String, silent: Bool, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
        transactions(dealId: dealId) { result in
            switch result {
            case .success(let txList):
                var type: TransactionType = .`init`
                if txList.isEmpty {
                    type = .`init`
                } else if txList.count == 1 && !txList[0].transaction.isEmpty {
                    return completion(.success(txList[0]))
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
