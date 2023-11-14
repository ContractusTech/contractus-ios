import Foundation
import Alamofire
import Base58Swift

fileprivate let HEADER_NAME = "X-Authorization"

public typealias KeyPair = (publicKey: String, privateKey: Data)

public struct AuthorizationHeaderData: Encodable {
    let blockchain: String
    let pubKey: String
    let signature: String
    let identifier: String
    let type: String = "IOS"
}

public struct AuthorizationHeader {
    let data: AuthorizationHeaderData
    let value: HTTPHeader
    let expiredAt: Date

    public init(data: AuthorizationHeaderData, expiredAt: Date) throws {
        self.data = data
        self.expiredAt = expiredAt
        let header = try JSONEncoder().encode(data)
        self.value = HTTPHeader(name: HEADER_NAME, value: header.base64EncodedString())
    }
}

public struct AuthorizationHeaderBuilder {
    public static func build(for signer: Signer, message: String, identifier: String, expiredAt: Date) throws -> AuthorizationHeader {
        let sign = try signer.sign(data: message.data(using: .utf8)!)
        let signatureBase58 = Base58.base58Encode([UInt8](sign))
        return try AuthorizationHeader(data: AuthorizationHeaderData(blockchain: signer.blockchain.rawValue, pubKey: signer.getPublicKey(), signature: signatureBase58, identifier: identifier), expiredAt: expiredAt)
    }
}
