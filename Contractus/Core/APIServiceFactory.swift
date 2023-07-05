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
        return ContractusAPI.AccountService(client: AppManager.shared.client)
    }

    func makeTransactionsService() throws -> ContractusAPI.TransactionsService {
        try checkAccount()
        return ContractusAPI.TransactionsService(client: AppManager.shared.client)
    }

    func makeFileService() throws -> ContractusAPI.FilesService {
        try checkAccount()
        return ContractusAPI.FilesService(client: AppManager.shared.client)
    }

    func makeResourcesService() throws -> ContractusAPI.ResourcesService {
        try checkAccount()
        return ContractusAPI.ResourcesService(client: AppManager.shared.client)
    }

    func makeDealsService() throws -> ContractusAPI.DealsService {
        try checkAccount()
        return ContractusAPI.DealsService(client: AppManager.shared.client)
    }

    // MARK: - Private Methods

    private func checkAccount() throws {
        guard !AppManager.shared.accountIsEmpty else { throw APIServiceFactoryError.accountNotSet }
    }
}
