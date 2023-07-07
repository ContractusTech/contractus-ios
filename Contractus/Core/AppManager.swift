import Foundation
import ContractusAPI
import DeviceCheck

final class ServiceClient {
    static let shared = ServiceClient(client: .init(server: AppConfig.serverType))
    public let client: ContractusAPI.APIClient

    private init(client: ContractusAPI.APIClient) {
        self.client = client
    }
}

protocol AppManager {
    var currentAccount: CommonAccount! { get }
    func sync() async throws
    func setAccount(for account: CommonAccount)
    func clearAccount()
}

final class AppManagerImpl: AppManager {

    public enum AppManagerError: Error {
        case syncError, invalidDeviceToke, noCurrentAccount, invalidSignMessage
    }

    public static let shared = AppManagerImpl(
        accountStorage: KeychainAccountStorage(),
        idService: ServiceFactory.shared.makeIdService(),
        authStorage: KeychainAuthStorage(),
        authService: APIServiceFactory.shared.makeAuthService())

    private(set) var accountIsEmpty = true
    public var deviceId: String!

    private(set) var currentAccount: CommonAccount!

    private let accountStorage: AccountStorage
    private let idService: IdentifierService
    private let authStorage: AuthStorage
    private let authService: ContractusAPI.AuthService

    private(set) var webSocket: WebSocket!

    private init(accountStorage: AccountStorage, idService: IdentifierService, authStorage: AuthStorage, authService: ContractusAPI.AuthService) {
        self.idService = idService
        self.accountStorage = accountStorage
        self.authStorage = authStorage
        self.authService = authService

        ServiceClient.shared.client.performVerifyDevice { callback in
            self.refreshMessage { result in
                callback(result)
            }
        }
    }

    func setAccount(for account: CommonAccount) {

        currentAccount = account

        guard let message = authStorage.getMessageForSign(), let header = try? buildHeader(for: account, identifier: idService.identifier, message: message) else {
            ServiceClient.shared.client.updateHeader(authorizationHeader: nil)
            accountIsEmpty = true
            currentAccount = nil
            if webSocket != nil {
                webSocket.disconnect()
                webSocket = nil
            }
            return
        }

        ServiceClient.shared.client.updateHeader(authorizationHeader: header)

        if webSocket == nil {
            webSocket = ContractusAPI.WebSocket(server: ServiceClient.shared.client.server, header: header)
        } else {
            webSocket.update(header: header)
        }

        webSocket.disconnectHandler = {
            
        }
        accountIsEmpty = false
    }

    func clearAccount() {
        ServiceClient.shared.client.updateHeader(authorizationHeader: nil)
        accountStorage.clearCurrentAccount()
        accountIsEmpty = true
        authStorage.clear()
        webSocket?.disconnect()
    }

    func sync() async throws {
        await idService.sync()

        guard let deviceToken = idService.deviceToken else {
            throw AppManagerError.syncError
        }

        if authStorage.getMessageForSign() == nil {
            let message = try await verifyDeviceToken(deviceToken: deviceToken, identifier: idService.identifier)
            try authStorage.saveMessageForSign(message.message, date: message.expiredAt)
        }

        guard let account = accountStorage.getCurrentAccount() else {
            throw AppManagerError.noCurrentAccount
        }

        setAccount(for: account)

        if currentAccount == nil {
            throw AppManagerError.noCurrentAccount
        }
    }

    private func buildHeader(for account: CommonAccount, identifier: String, message: String) throws -> ContractusAPI.AuthorizationHeader {
        return try AuthorizationHeaderBuilder.build(
            for: account.blockchain,
            message: message,
            with: (publicKey: account.publicKey, privateKey: account.privateKey),
            identifier: identifier
        )
    }

    private func verifyDeviceToken(deviceToken: String, identifier: String) async throws -> DeviceMessage {
        try await withCheckedThrowingContinuation { continuation in
            authService.verifyDevice(data: .init(deviceToken: deviceToken, identifier: identifier)) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func refreshMessage(callback: @escaping (Result<AuthorizationHeader, Error>) -> Void) {
        guard let deviceToken = idService.deviceToken, let identifier = idService.identifier else {
            callback(.failure(AppManagerError.syncError))
            return
        }

        authService.verifyDevice(data: .init(deviceToken: deviceToken, identifier: identifier)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                callback(.failure(error))
            case .success(let message):
                do {
                    let header = try self.buildHeader(for: self.currentAccount, identifier: identifier, message: message.message)
                    callback(.success(header))
                } catch {
                    callback(.failure(error))
                }
            }

        }

    }

}


class MockAppManager: AppManager {
    var currentAccount: CommonAccount!

    func sync() async throws { }

    func setAccount(for account: CommonAccount) {
        currentAccount = account
    }

    func clearAccount() {
        currentAccount = nil
    }
}
