import Foundation

fileprivate let productionAddress = "s.contractus.tech"
fileprivate let developerAddress = "dev.contractus.tech"
fileprivate let localAddress = "localhost"

public enum Blockchain: String, CaseIterable, Hashable {
    case solana
}

public enum ServerType {

    public enum APIVersion: String {
        case v1, none
    }

    case production(APIVersion = .v1)
    case developer(APIVersion = .v1)
    case local(APIVersion = .v1, Int = 3000, Int = 3001)
    case custom(api: URL, ws: URL)

    public var apiURL: URL {
        switch self {
        case .production(let version):
            return server.appendingPathComponent("api").appendingPathComponent(version.rawValue)
        case .developer(let version):
            return server.appendingPathComponent("api").appendingPathComponent(version.rawValue)
        case .local(let version, _, _):
            return server.appendingPathComponent(version.rawValue)
        case .custom(let url, _):
            return url
        }
    }

    public var wsURL: URL {
        switch self {
        case .production:
            return wsServer.appendingPathComponent("ws")
        case .developer:
            return wsServer.appendingPathComponent("ws")
        case .local:
            return wsServer.appendingPathComponent("ws")
        case .custom:
            return wsServer
        }
    }

    public var version: APIVersion {
        switch self {
        case .production(let version):
            return version
        case .developer(let version):
            return version
        case .local(let version, _, _):
            return version
        case .custom(_, _):
            return .none
        }
    }

    public var server: URL {
        switch self {
        case .production:
            return URL(string: "https://\(productionAddress)")!
        case .developer:
            return URL(string: "https://\(developerAddress)")!
        case .local( _, let port, _):
            return URL(string: "http://\(localAddress):\(port)")!
        case .custom(let apiUrl, _):
            return apiUrl
        }
    }

    public var wsServer: URL {
        switch self {
        case .production:
            return URL(string: "wss://\(productionAddress)")!
        case .developer:
            return URL(string: "wss://\(developerAddress)")!
        case .local( _, _, let port):
            return URL(string: "ws://\(localAddress):\(port)")!
        case .custom(_, let wsUrl):
            return wsUrl
        }
    }

    public func path(_ path: String) -> URL {
        return self.apiURL.appendingPathComponent(path)
    }

    public var title: String {
        switch self {
        case .production:
            return "Production"
        case .developer(_):
            return "Developer"
        case .local:
            return "Local"
        case .custom:
            return "Custom"
        }
    }

    public var network: String {
        switch self {
        case .production:
            return "Mainnet"
        case .developer(_):
            return "Devnet"
        case .local:
            return "Devnet"
        case .custom:
            return "Custom"
        }
    }

    public var isDevelop: Bool {
        switch self {
        case .developer, .local:
            return true
        default:
            return false
        }
    }
}
