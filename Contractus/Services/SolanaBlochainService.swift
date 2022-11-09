//
//  SolanaBlochainService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 06.08.2022.
//

import Foundation
import SolanaSwift
import ContractusAPI

// TODO: - Не использовать, есть метод на бэке
//
//final class SolanaBlochainSerivce: BlockchainService {
//
//    enum Constants {
//        static let apiKey = "cff79dde-1a2e-49af-9359-3f49c53bfc65"
//    }
//
//    enum Mint {
//        static let usdc = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
//    }
//
//    enum ServiceError: Error {
//        case NotFoundNetwork
//        case InvalidRequest
//    }
//
//    let client: JSONRPCAPIClient
//
//    init(network: Network = .devnet) throws {
//        guard let endpoint = APIEndPoint.defaultEndpoints.first(where: { $0.network == network }) else {
//            throw ServiceError.NotFoundNetwork
//        }
//        client = JSONRPCAPIClient(endpoint: endpoint)
//    }
//
//    func getBalances(publicKey: String, estimateCurrency: Currency) async -> Balance {
//        do {
//            let solanaBalance = try await client.getBalance(account: publicKey)
//            let usdcBalance = try await client.getTokenAccountsByOwner(pubkey: publicKey, params: OwnerInfoParams.init(mint: Mint.usdc, programId: nil))
//            let estimate = (try? await getEstimate(solanaAmount: 1000)) ?? 0
//            return Balance(
//                estimateBalance: Amount("\(estimate)", currency: estimateCurrency).formatted(),
//                usdc: Amount("0", currency: .usdc),
//                sol: Amount(solanaBalance, currency: .sol))
//        } catch {
//
//        }
//        return Balance(
//            estimateBalance: Amount("0", currency: estimateCurrency).formatted(),
//            usdc: Amount("0", currency: .usdc),
//            sol: Amount("0", currency: .sol))
//    }
//
//    private func getEstimate(solanaAmount: UInt64) async throws -> Double {
//
//        let balance: Double = try await withCheckedThrowingContinuation({ continuation in
//
//            let queryItems = [
//                URLQueryItem(name: "symbol", value: "SOL"),
//                URLQueryItem(name: "amount", value: "\(solanaAmount)"),
//                URLQueryItem(name: "convert", value: "USD"),
//            ]
//            guard var urlComponents = URLComponents(string: "https://pro-api.coinmarketcap.com/v2/tools/price-conversion") else {
//                continuation.resume(throwing: ServiceError.InvalidRequest)
//                return
//            }
//            urlComponents.queryItems = queryItems
//            guard let url = urlComponents.url else {
//                continuation.resume(throwing: ServiceError.InvalidRequest)
//                return
//            }
//            guard var request = try? URLRequest(
//                url: url,
//                method: .get) else {
//                continuation.resume(throwing: ServiceError.InvalidRequest)
//                return
//            }
//            request.addValue(Constants.apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                guard let data = data else {
//                    continuation.resume(throwing: ServiceError.InvalidRequest)
//                    return
//                }
//                guard let response = try? JSONDecoder().decode(EstimateResponse.self, from: data) else {
//                    continuation.resume(throwing: ServiceError.InvalidRequest)
//                    return
//                }
//
//                continuation.resume(returning: response.quote["USD"]?.price ?? 0)
//            }.resume()
//        })
//
//        return balance
//
//    }
//}
