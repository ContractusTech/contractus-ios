//
//  BaseService.swift
//  
//
//  Created by Simon Hudishkin on 30.07.2022.
//

import Foundation
import Alamofire

public enum ServicePath {
    case accounts
    case deals
    case availableCurrencies
    case dealMetadata(String)
    case dealResult(String)
    case dealTransactions(String)
    case dealTransaction(String, TransactionType)
    case dealSign(String, TransactionType)
    case uploadFile
    case deal(String)
    case participant(String)
    case balance

    var value: String {
        switch self {
        case .accounts:
            return "/accounts"
        case .uploadFile:
            return "/files/upload"
        case .deals:
            return "/deals"
        case .deal(let id):
            return "/deals/\(id)"
        case .dealMetadata(let id):
            return "/deals/\(id)/meta"
        case .availableCurrencies:
            return "/resources/currencies"
        case .dealTransactions(let id):
            return "/deals/\(id)/tx"
        case .dealTransaction(let id, let type):
            return "/deals/\(id)/tx/\(type.rawValue)"
        case .dealSign(let id, let type):
            return "/deals/\(id)/tx/\(type.rawValue)/sign"
        case .participant(let id):
            return "/deals/\(id)/participate"
        case .balance:
            return "/accounts/balance"
        case .dealResult(let id):
            return "/deals/\(id)/result"
        }
    }
}

public class BaseService {

    let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func setAuthorization(_ authorizationHeader: AuthorizationHeader?) {
        client.updateHeader(authorizationHeader: authorizationHeader)
    }

    func request<T: Decodable, E: Encodable>(
        path: ServicePath,
        httpMethod: HTTPMethod,
        data: E? = nil,
        completion: @escaping (Swift.Result<T, APIClientError>) -> Void)
    {
        let encoder: ParameterEncoder
        switch httpMethod {
        case .get:
            encoder = URLEncodedFormParameterEncoder.default
        default:
            encoder = JSONParameterEncoder.default
        }
        client.session.request(client.server.path(path.value), method: httpMethod, parameters: data, encoder: encoder)
            .validate()
            .responseDecodable(of: T.self) {[weak self] response in
                guard let self = self else { return }
                debugPrint(String(data: response.request?.httpBody ?? Data(), encoding: .utf8))
                completion(self.process(response: response))
        }
    }

    func process<T: Decodable>(response: AFDataResponse<T>) -> Swift.Result<T, APIClientError> {
        debugPrint(String(data: response.data ?? Data(), encoding: .utf8))
        guard let value = response.value else {
            if let error = self.parseError(data: response.data) {
                return .failure(error)
            }
            if let error = response.error {
                return .failure(.commonError(error))
            }
            return .failure(.unknownError)
        }
        return .success(value)
    }

    private func parseError(data: Data?) -> APIClientError? {
        if let data = data, let error = try? JSONDecoder().decode(ServiceError.self, from: data) {
            return APIClientError.serviceError(error)
        }
        return nil
    }
}
