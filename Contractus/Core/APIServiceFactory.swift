//
//  ServiceFactory.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import Foundation
import ContractusAPI
import SolanaSwift
import UIKit

final class APIServiceFactory {
    enum APIServiceFactoryError: Error {
        case accountNotSet
    }

    // MARK: - Shared
    static let shared = APIServiceFactory()

    private init() {}

    // MARK: - Public Methods

    
    func makeAccountService() throws -> ContractusAPI.AccountService {
        try checkAccount()
        return ContractusAPI.AccountService(client: ServiceClient.shared.client)
    }

    func makeTransactionsService() throws -> ContractusAPI.TransactionsService {
        try checkAccount()
        return ContractusAPI.TransactionsService(client: ServiceClient.shared.client)
    }

    func makeFileService() throws -> ContractusAPI.FilesService {
        try checkAccount()
        return ContractusAPI.FilesService(client: ServiceClient.shared.client)
    }

    func makeResourcesService() throws -> ContractusAPI.ResourcesService {
        try checkAccount()
        return ContractusAPI.ResourcesService(client: ServiceClient.shared.client)
    }

    func makeDealsService() throws -> ContractusAPI.DealsService {
        try checkAccount()
        return ContractusAPI.DealsService(client: ServiceClient.shared.client)
    }

    func makeAuthService() -> ContractusAPI.AuthService {
        return ContractusAPI.AuthService(client: ServiceClient.shared.client)
    }

    func makeReferralsService() -> ContractusAPI.ReferralService {
        return ContractusAPI.ReferralService(client: ServiceClient.shared.client)
    }

    func makeCheckoutService() -> ContractusAPI.CheckoutService {
        return ContractusAPI.CheckoutService(client: ServiceClient.shared.client)
    }

    // MARK: - Private Methods

    private func checkAccount() throws {
        guard ServiceClient.shared.client.hasHeader else { throw APIServiceFactoryError.accountNotSet }
    }
}
