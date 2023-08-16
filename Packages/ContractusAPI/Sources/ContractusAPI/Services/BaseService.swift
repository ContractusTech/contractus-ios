//
//  BaseService.swift
//  
//
//  Created by Simon Hudishkin on 30.07.2022.
//

import Foundation
import Alamofire

public enum ServicePath {
    case verifyDevice
    case accounts
    case currentAccount
    case accountStatistics
    case deals
    case transactions
    case transaction(String)
    case tokens
    case dealMetadata(String)
    case dealResult(String)
    case dealTransactions(String)
    case cancelDeal(String)
    case dealTransaction(String, TransactionType)
    case dealSign(String, TransactionType)
    case uploadFile
    case deal(String)
    case dealAction(String)
    case participant(String)
    case balance
    case dealFee(dealId: String)
    case wrap
    case signWrap
    case unwrap
    case signUnwrap
    case referral
    case createPromocode
    case applyPromocode

    var value: String {
        switch self {
        case .verifyDevice:
            return "/auth/verify-device"
        case .wrap:
            return "/tx/wrap"
        case .signWrap:
            return "/tx/wrap/sign"
        case .unwrap:
            return "/tx/unwrap-all"
        case .signUnwrap:
            return "/tx/unwrap-all/sign"
        case .transactions:
            return "/tx"
        case .transaction(let id):
            return "/tx/\(id)"
        case .accounts:
            return "/accounts"
        case .currentAccount:
            return "/accounts/my"
        case .uploadFile:
            return "/files/upload"
        case .deals:
            return "/deals"
        case .deal(let id):
            return "/deals/\(id)"
        case .dealAction(let id):
            return "/deals/\(id)/actions"
        case .dealMetadata(let id):
            return "/deals/\(id)/meta"
        case .tokens:
            return "/resources/tokens"
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
        case .accountStatistics:
            return "/accounts/statistics"
        case .dealResult(let id):
            return "/deals/\(id)/result"
        case .cancelDeal(let id):
            return "/deals/\(id)/cancel"
        case .dealFee(let dealId):
            return "/deals/\(dealId)/fee"
        case .applyPromocode:
            return "/referrals/apply"
        case .referral:
            return "/referrals"
        case .createPromocode:
            return "/referrals"

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
        withAuth: Bool = true,
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
        (withAuth ? client.session : Session.default).request(client.server.path(path.value), method: httpMethod, parameters: data, encoder: encoder)
            .validate()
            .responseDecodable(of: T.self) {[weak self] response in
                guard let self = self else { return }
                completion(self.process(response: response))
        }
    }

    func process<T: Decodable>(response: AFDataResponse<T>) -> Swift.Result<T, APIClientError> {
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
