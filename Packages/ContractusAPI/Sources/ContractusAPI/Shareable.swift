import Foundation

public enum ShareableError: Error {
    case invalidContent
}

public protocol Shareable {
    init(shareContent: String) throws
    var shareContent: String { get }
}
