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
    private let server: ServerType

    private var accountIsEmpty = true
    private var webSocket: WebSocket!

    init(for server: ContractusAPI.ServerType) {
        self.server = server
        client = ContractusAPI.APIClient(server: server)

    }

    // MARK: - Public Methods

    func setAccount(for account: CommonAccount, deviceId: String = AppConfig.deviceId) {
        guard let header = try? buildHeader(for: account, deviceId: deviceId) else {
            client.updateHeader(authorizationHeader: nil)
            accountIsEmpty = true
            if webSocket != nil {
                webSocket.disconnect()
                webSocket = nil
            }
            return
        }

        client.updateHeader(authorizationHeader: header)

        if webSocket == nil {
            webSocket = ContractusAPI.WebSocket(server: server, header: header)
        } else {
            webSocket.update(header: header)
        }
        accountIsEmpty = false
    }

    func clearAccount() {
        client.updateHeader(authorizationHeader: nil)
        accountIsEmpty = true
    }

    func makeAccountService() throws -> ContractusAPI.AccountService {
        try checkAccount()
        return ContractusAPI.AccountService(client: client)
    }

    func makeTransactionsService() throws -> ContractusAPI.TransactionsService {
        try checkAccount()
        return ContractusAPI.TransactionsService(client: client)
    }

    func makeFileService() throws -> ContractusAPI.FilesService {
        try checkAccount()
        return ContractusAPI.FilesService(client: client)
    }

    func makeResourcesService() throws -> ContractusAPI.ResourcesService {
        try checkAccount()
        return ContractusAPI.ResourcesService(client: client)
    }

    func makeDealsService() throws -> ContractusAPI.DealsService {
        try checkAccount()
        return ContractusAPI.DealsService(client: client)
    }

    func makeWebSocket() throws -> ContractusAPI.WebSocket {
        try checkAccount()
        return webSocket
    }

    // MARK: - Private Methods

    private func checkAccount() throws {
        guard !accountIsEmpty else { throw APIServiceFactoryError.accountNotSet }
    }

    private func buildHeader(for account: CommonAccount, deviceId: String) throws -> ContractusAPI.AuthorizationHeader {
        return try AuthorizationHeaderBuilder.build(
            for: account.blockchain,
            with: (publicKey: account.publicKey, privateKey: account.privateKey),
            deviceId: deviceId
        )
    }
}
