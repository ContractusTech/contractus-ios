//
//  AuthorizationHeaderFactory.swift
//  
//
//  Created by Simon Hudishkin on 24.07.2022.
//

import Foundation
import Alamofire
import TweetNacl
import Base58Swift

fileprivate let HEADER_NAME = "X-Authorization"

public typealias KeyPair = (publicKey: String, privateKey: Data)

public struct AuthorizationHeaderData: Encodable {
    let blockchain: String
    let pubKey: String
    let signature: String
    let deviceId: String
}

public struct AuthorizationHeader {
    let data: AuthorizationHeaderData
    let value: HTTPHeader

    public init(data: AuthorizationHeaderData) throws {
        self.data = data
        let header = try JSONEncoder().encode(data)
        self.value = HTTPHeader(name: HEADER_NAME, value: header.base64EncodedString())
    }
}

public struct AuthorizationHeaderBuilder {

    public static func build(for blockchain: Blockchain, with keyPair: KeyPair, deviceId: String) throws -> AuthorizationHeader {
        switch blockchain {
        case .solana:
            let sign = try NaclSign.signDetached(
                message: blockchain.rawValue.data(using: .utf8)!,
                secretKey: keyPair.privateKey)

            let signatureBase58 = Base58.base58Encode([UInt8](sign))
            return try AuthorizationHeader(data: AuthorizationHeaderData(blockchain: blockchain.rawValue, pubKey: keyPair.publicKey, signature: signatureBase58, deviceId: deviceId))

        }
    }
}
