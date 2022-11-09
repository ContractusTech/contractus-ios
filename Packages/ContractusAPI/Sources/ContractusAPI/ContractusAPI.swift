import Foundation


public enum Blockchain: String {
    case solana
}

public enum ServerType {
    case production, developer, custom(String)

    var serverURL: URL {
        switch self {
        case .production:
            fatalError("No server")
        case .developer:
            fatalError("No server")
        case .custom(let url):
            return URL(string: url)!
        }
    }

    func path(_ path: String) -> URL {
        return self.serverURL.appendingPathComponent(path)
    }
}
