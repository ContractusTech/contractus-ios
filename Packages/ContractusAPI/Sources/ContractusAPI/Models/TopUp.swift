import Foundation

public struct TopUpMethods: Decodable {
    public struct Method: Decodable {
        public let url: String?
        public let type: String
    }

    public let methods: [Method]
}

extension TopUpMethods: Equatable {
    public static func == (lhs: TopUpMethods, rhs: TopUpMethods) -> Bool {
        rhs.methods == lhs.methods
    }
}
extension TopUpMethods.Method: Equatable {
    public static func == (lhs: TopUpMethods.Method, rhs: TopUpMethods.Method) -> Bool {
        lhs.type == rhs.type && lhs.url == rhs.url
    }
}
