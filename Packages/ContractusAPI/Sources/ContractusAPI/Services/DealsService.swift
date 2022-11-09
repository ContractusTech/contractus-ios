//
//  DealsService.swift
//  
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import Alamofire

public final class DealsService: BaseService {

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

    public func update(dealId: String, data: UpdateDeal, completion: @escaping (Swift.Result<Deal, APIClientError>) -> Void) {
        self.request(path: .deal(dealId), httpMethod: .post, data: data) { (result: Swift.Result<Deal, APIClientError>) in
            completion(result)
        }
    }

    public func updateMetadata(dealId: String, meta: DealMetadata, completion: @escaping (Swift.Result<DealMetadata, APIClientError>) -> Void) {
        self.request(path: .dealMetadata(dealId), httpMethod: .post, data: meta) { (result: Swift.Result<DealMetadata, APIClientError>) in
            completion(result)
        }
    }

    public func transactions(dealId: String, completion: @escaping (Swift.Result<[DealTransaction], APIClientError>) -> Void) {
        self.request(path: .dealTransactions(dealId), httpMethod: .get, data: Empty()) { (result: Swift.Result<[DealTransaction], APIClientError>) in
            completion(result)
        }
    }

    public func getTransaction(dealId: String, type: TransactionType, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
        self.request(path: .dealTransaction(dealId, type), httpMethod: .get, data: Empty()) { (result: Swift.Result<DealTransaction, APIClientError>) in
            completion(result)
        }
    }

    public func signTransaction(dealId: String, type: TransactionType, data: SignedDealTransaction, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
        self.request(path: .dealSign(dealId, type), httpMethod: .post, data: data) { (result: Swift.Result<DealTransaction, APIClientError>) in
            completion(result)
        }
    }

    public func getActualTransaction(dealId: String, completion: @escaping (Swift.Result<DealTransaction, APIClientError>) -> Void) {
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

                self.getTransaction(dealId: dealId, type: type) { result in
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
}
