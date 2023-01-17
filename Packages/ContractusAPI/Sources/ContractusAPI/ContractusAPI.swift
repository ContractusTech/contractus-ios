import Foundation


public enum Blockchain: String, CaseIterable, Hashable {
    case solana
}

public enum ServerType {

    public enum APIVersion: String {
        case v1
    }

    case production(APIVersion = .v1), developer(APIVersion = .v1), custom(String, APIVersion = .v1)

    var apiURL: URL {
        switch self {
        case .production:
            fatalError("No production server")
        case .developer:
            fatalError("No developer server")
        case .custom(_, let version):
            return server.appendingPathComponent(version.rawValue)
        }
    }

    var server: URL {
        switch self {
        case .production:
            fatalError("No production server")
        case .developer:
            fatalError("No developer server")
        case .custom(let url, _):
            return URL(string: url)!
        }
    }

    func path(_ path: String) -> URL {
        return self.apiURL.appendingPathComponent(path)
    }
}
