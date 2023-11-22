import Foundation
public protocol Signer {
    var blockchain: Blockchain { get }
    func sign(data: Data) throws -> Data
    func getPublicKey() -> String
    func encodeSignature(_ signature: Data) -> String
}

public enum SignerError: Error {
    case emptyHash, emptySignature
}
