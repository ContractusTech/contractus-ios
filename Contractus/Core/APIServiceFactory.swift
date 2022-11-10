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
    static let shared = APIServiceFactory(for: AppConfig.serverType)

    // MARK: - Private Properties

    private let client: ContractusAPI.APIClient
    private var accountIsEmpty = true


    init(for server: ContractusAPI.ServerType) {
        client = ContractusAPI.APIClient(server: server)
    }

    // MARK: - Public Methods

    func setAccount(for account: CommonAccount, deviceId: String) {
        guard let header = try? buildHeader(for: account, deviceId: deviceId) else {
            client.updateHeader(authorizationHeader: nil)
            accountIsEmpty = true
            return
        }
        client.updateHeader(authorizationHeader: header)
        accountIsEmpty = false
    }

    func clearAccount() {
        client.updateHeader(authorizationHeader: nil)
    }

    func makeAccountService() throws -> ContractusAPI.AccountService {
        try checkAccount()
        return ContractusAPI.AccountService(client: client)
    }

    func makeFileService() throws -> ContractusAPI.FilesService {
        try checkAccount()
        return ContractusAPI.FilesService(client: client)
    }

    func makeDealsService() throws -> ContractusAPI.DealsService {
        try checkAccount()
        return ContractusAPI.DealsService(client: client)
    }

    // MARK: - Private Methods

    private func checkAccount() throws {
        if accountIsEmpty {
            throw APIServiceFactoryError.accountNotSet
        }
    }

    private func buildHeader(for account: CommonAccount, deviceId: String) throws -> ContractusAPI.AuthorizationHeader {
        return try AuthorizationHeaderBuilder.build(
            for: account.blockchain,
            with: (publicKey: account.publicKey, privateKey: account.privateKey),
            deviceId: deviceId
        )
    }
}
