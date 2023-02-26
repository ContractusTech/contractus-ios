import Foundation


public enum Blockchain: String, CaseIterable, Hashable {
    case solana
}

public enum ServerType {

    public enum APIVersion: String {
        case v1
    }

    case production(APIVersion = .v1), developer(APIVersion = .v1), custom(URL, APIVersion = .v1)

    public var apiURL: URL {
        switch self {
        case .production:
            fatalError("No production server")
        case .developer(let version):
            return server.appendingPathComponent(version.rawValue)
        case .custom(_, let version):
            return server.appendingPathComponent(version.rawValue)
        }
    }

    public var version: APIVersion {
        switch self {
        case .production:
            fatalError("No production server")
        case .developer(let version):
            return version
        case .custom(_, let version):
            return version
        }
    }

    public var server: URL {
        switch self {
        case .production:
            fatalError("No production server")
        case .developer:
            return URL(string: "https://dev.contractus.tech")!
        case .custom(let url, _):
            return url
        }
    }

    public func path(_ path: String) -> URL {
        return self.apiURL.appendingPathComponent(path)
    }
}
