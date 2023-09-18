import Foundation
import ContractusAPI
import DeviceCheck
import FirebaseCrashlytics

final class ServiceClient {
    static let shared = ServiceClient(client: .init(
        server: AppConfig.serverType,
        info: .init(version: AppConfig.version, build: AppConfig.buildNumber))
    )
    public let client: ContractusAPI.APIClient

    private init(client: ContractusAPI.APIClient) {
        self.client = client
    }
}

protocol AppManager: AnyObject {
    var currentAccount: CommonAccount! { get }
    var invalidDeviceHandler: ((Error) -> Void)? { get set }

    func sync() async throws
    func setAccount(for account: CommonAccount)
    func clearAccount()
    func debugInfo() -> [String]
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

    var invalidDeviceHandler: ((Error) -> Void)?
    
    private(set) var accountIsEmpty = true
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

        ServiceClient.shared.client.setBlockedAuthorizationHandler { error in
            self.invalidDeviceHandler?(error)
        }
    }

    func setAccount(for account: CommonAccount) {

        currentAccount = account

        guard let (message, expiredAt) = authStorage.getMessageForSign(), let header = try? buildHeader(for: account, identifier: idService.identifier, message: message, expiredAt: expiredAt) else {
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

        webSocket.disconnectHandler = { }
        accountIsEmpty = false

        accountStorage.setCurrentAccount(account: account)
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
            do {
                let message = try await verifyDeviceToken(deviceToken: deviceToken, identifier: idService.identifier)
                try authStorage.saveMessageForSign(message.message, date: message.expiredAt)
            } catch(let error) {
                Crashlytics.crashlytics().record(error: error)
                if error.asAFError?.responseCode == 423 {
                    authStorage.clear()
                }
                throw AppManagerError.invalidSignMessage
            }
        }


        guard let account = accountStorage.getCurrentAccount() else {
            throw AppManagerError.noCurrentAccount
        }

        setAccount(for: account)

        if currentAccount == nil {
            throw AppManagerError.noCurrentAccount
        }
    }

    func debugInfo() -> [String] {
        [
            "Identificator: \n\(idService.identifier ?? "-")",
            // "Token: \n\(idService.deviceToken ?? "-")",
            "DeviceInfo: \n\(UIDevice.current.systemName), \(UIDevice.current.model), \(UIDevice.current.systemVersion)"

        ]
    }

    private func buildHeader(for account: CommonAccount, identifier: String, message: String, expiredAt: Date) throws -> ContractusAPI.AuthorizationHeader {
        return try AuthorizationHeaderBuilder.build(
            for: account.blockchain,
            message: message,
            with: (publicKey: account.publicKey, privateKey: account.privateKey),
            identifier: identifier,
            expiredAt: expiredAt
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
                self.invalidDeviceHandler?(error)
                callback(.failure(error))
            case .success(let message):
                do {
                    let header = try self.buildHeader(
                        for: self.currentAccount,
                        identifier: identifier,
                        message: message.message,
                        expiredAt: message.expiredAt)

                    try? self.authStorage.saveMessageForSign(message.message, date: message.expiredAt)
                    callback(.success(header))
                } catch {
                    callback(.failure(error))
                }
            }

        }

    }

}


class MockAppManager: AppManager {

    var invalidDeviceHandler: ((Error) -> Void)?
    var currentAccount: CommonAccount!

    func sync() async throws { }

    func setAccount(for account: CommonAccount) {
        currentAccount = account
    }

    func clearAccount() {
        currentAccount = nil
    }

    func debugInfo() -> [String] {
        []
    }
}
