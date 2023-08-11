//
//  SharedSecretService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 09.02.2023.
//

import Foundation
import ShamirSecretSharing

enum SharedSecretService {

    enum SharedSecretServiceError: Error {
        case invalidSecretKey, invalidData
    }
    struct SharedSecret {
        let secretKey: Data
        let base64EncodedSecret: String
        let hashOriginalKey: String
        let serverSecret: Data
        let clientSecret: Data
    }

    static func createSharedSecret(privateKey: Data) async throws -> SharedSecret {
        let key = String.random(length: AppConfig.sharedKeyLength)
        let uInt8array = [UInt8](key.utf8)
        return try await getSharedSecret(key: uInt8array, privateKey: privateKey)
    }

    static func encryptSharedSecretKey(base64String: String, hashOriginalKey: String?, privateKey: Data) async throws -> SharedSecret {
        guard let encryptedData = Data(base64Encoded: base64String) else {
            throw SharedSecretServiceError.invalidData
        }

        let decryptedData = try await Crypto.decrypt(encryptedData: encryptedData, with: privateKey)
        guard let sharedKeys = try? JSONDecoder().decode([[UInt8]].self, from: decryptedData),
              sharedKeys.count == 2,
              let serverSecret = sharedKeys.first,
              let clientSecret = sharedKeys.last
        else {
            throw SharedSecretServiceError.invalidData
        }
        guard let secretKeyData = try? SSS.combineShares(data: sharedKeys) else {
            throw SharedSecretServiceError.invalidSecretKey
        }
        if let hashOriginalKey = hashOriginalKey {
            guard Crypto.sha3(data: Data(secretKeyData)) == hashOriginalKey else {
                throw SharedSecretServiceError.invalidSecretKey
            }
        }

        return .init(
            secretKey: Data(secretKeyData),
            base64EncodedSecret: base64String,
            hashOriginalKey: hashOriginalKey ?? "",
            serverSecret: Data(serverSecret),
            clientSecret: Data(clientSecret))
    }

    static func recover(serverSecret: Data, clientSecret: Data, hashOriginalKey: String) async throws -> Data {
        let uint8ArrayServer = [UInt8](serverSecret)
        let uint8ArrayClient = [UInt8](clientSecret)

        guard let key = try SSS.combineShares(data: [uint8ArrayServer, uint8ArrayClient]) else {
            throw SharedSecretServiceError.invalidSecretKey
        }
        guard Crypto.sha3(data: Data(key)) == hashOriginalKey else {
            throw SharedSecretServiceError.invalidSecretKey
        }
        return Data(key)
    }

    private static func getSharedSecret(key: [UInt8], privateKey: Data) async throws -> SharedSecret {
        guard
            let sharedParts = try? SSS.createShares(data: key),
            sharedParts.count == 2,
            let serverSecret = sharedParts.first,
            let clientSecret = sharedParts.last else
        {
            throw SharedSecretServiceError.invalidSecretKey
        }

        let jsonObject = try JSONEncoder().encode(sharedParts)
        let encryptedSharedKeys = try await Crypto.encrypt(data: jsonObject, with: privateKey)
        return .init(
            secretKey: Data(key),
            base64EncodedSecret: encryptedSharedKeys.base64EncodedString(),
            hashOriginalKey: Crypto.sha3(data: Data(key)),
            serverSecret: Data(serverSecret),
            clientSecret: Data(clientSecret))
    }
}
