import Foundation
import ContractusAPI
import DeviceCheck

class AppManager {

    public static let shared = AppManager()

    private(set) var accountIsEmpty = true
   
    public let client: ContractusAPI.APIClient
    public let server: ServerType
    public var deviceId: String!
    private let authStorage: AuthStorage = KeychainAuthStorage()

    private(set) var webSocket: WebSocket!

    private init() {
        self.client = .init(server: AppConfig.serverType)
        self.server = AppConfig.serverType
    }

    func setAccount(for account: CommonAccount) {

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

    private func buildHeader(for account: CommonAccount, deviceId: String, message: String) throws -> ContractusAPI.AuthorizationHeader {
        return try AuthorizationHeaderBuilder.build(
            for: account.blockchain,
            message: message,
            with: (publicKey: account.publicKey, privateKey: account.privateKey),
            deviceId: deviceId
        )
    }

}
