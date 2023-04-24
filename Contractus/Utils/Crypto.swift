//
//  Crypto.swift
//  Contractus
//
//  Created by Simon Hudishkin on 02.08.2022.
//

import CryptoSwift
import Foundation
import Combine

struct Crypto {

    enum CryptoError: Error {
        case invalidData, error
    }

    fileprivate let iv: [UInt8] = [142, 5, 204, 20, 89, 164, 93, 38, 160, 30, 27, 173, 7, 170, 153, 183]
    private let key: [UInt8]
    private let aes: AES

    init(key: [UInt8]) throws {
        self.key = key
        aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
    }

    init(password: Data, salt: Data) throws {
        let key = try PKCS5.PBKDF2(
            password: password.bytes,
            salt: salt.bytes,
            iterations: 4096,
            keyLength: 32,
            variant: .sha2(.sha256)
        ).calculate()

        try self.init(key: key)
    }

    init(privateKey: Data) throws {
        self.key = Array(privateKey.bytes[0..<32])
        aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
    }

    func encrypt(message: String) throws -> Data {
        guard let inputData = message.data(using: .utf8) else { throw CryptoError.invalidData }
        return try self.encrypt(data: inputData)
    }

    func encrypt(data: Data) throws -> Data {
        let encryptedBytes = try aes.encrypt(data.bytes)
        return Data(encryptedBytes)
    }

    func decrypt(encryptedData: Data) throws -> Data {
        let decryptedBytes = try aes.decrypt(encryptedData.bytes)
        return Data(decryptedBytes)
    }
}

extension Crypto {

    // MARK: - Hash

    static func md5(data: Data) -> String {
        return data.md5().toHexString()
    }

    static func sha3(data: Data) -> String {
        return data.sha3(.sha256).toHexString()
    }

    static func checkSum(data: Data, hashMD5: String) -> Bool {
        return data.md5().toHexString() == hashMD5
    }

    static func checkSum(data: Data, hashSHA3: String) -> Bool {
        return data.sha3(.sha256).toHexString() == hashSHA3
    }

    // MARK: - Encrypt Methods

    static func encryptTask(data: Data, with privateKey: Data) -> Task<Data, Error> {
        let task = Task { () -> Data in
            let crypto = try Crypto(privateKey: privateKey)
            let encryptMessage = try crypto.encrypt(data: data)
            return encryptMessage
        }
        return task
    }

    static func encrypt(message: String, with privateKey: Data) async throws -> Data {
        guard let inputData = message.data(using: .utf8) else {
            throw CryptoError.invalidData
        }
        return try await Self.encrypt(data: inputData, with: privateKey)
    }

    static func encrypt(data: Data, with privateKey: Data) async throws -> Data {
        let task = Task { () -> Data in
            let crypto = try Crypto(privateKey: privateKey)
            let encryptMessage = try crypto.encrypt(data: data)
            return encryptMessage
        }

        return try await task.value
    }

    static func encrypt(message: String, with privateKey: Data) -> Future<Data, Error> {
        return Future { promise in
            guard let inputData = message.data(using: .utf8) else {
                promise(.failure(CryptoError.invalidData))
                return
            }
            Task {
                do {
                    let data = try await Self.encrypt(data: inputData, with: privateKey)
                    promise(.success(data))
                } catch(let error) {
                    promise(.failure(error))
                }
            }
        }
    }

    static func encrypt(data: Data, with privateKey: Data) -> Future<Data, Error>  {
        return Future { promise in
           Task {
               do {
                   let data = try await Self.encrypt(data: data, with: privateKey)
                   promise(.success(data))
               } catch(let error) {
                   promise(.failure(error))
               }

            }
        }
    }

    // MARK: - Decrypt Async Methods

    static func decrypt(encryptedData: Data, with privateKey: Data) async throws -> Data {
        let task = Task { () -> Data in
            let crypto = try Crypto(privateKey: privateKey)
            let decryptMessage = try crypto.decrypt(encryptedData: encryptedData)
            return decryptMessage
        }

        return try await task.value
    }

    static func decrypt(base64Encrypted: String, with privateKey: Data) async throws -> Data {
        guard let base64Data = Data(base64Encoded: base64Encrypted) else {
            throw CryptoError.invalidData
        }
        return try await decrypt(encryptedData: base64Data, with: privateKey)
    }

    // MARK: - Decrypt Combine Methods

    static func decrypt(encryptedData: Data, with privateKey: Data) -> Future<Data, Error>  {
        return Future { promise in
           Task {
               do {
                   let data = try await Self.decrypt(encryptedData: encryptedData, with: privateKey)
                   promise(.success(data))
               } catch(let error) {
                   promise(.failure(error))
               }

            }
        }
    }

    static func decrypt(base64Encrypted: String, with privateKey: Data) -> Future<Data, Error> {
        return Future { promise in
            guard let base64Data = Data(base64Encoded: base64Encrypted) else {
                promise(.failure(CryptoError.invalidData))
                return
            }
            Task {
                do {
                    let data = try await Self.decrypt(encryptedData: base64Data, with: privateKey)
                    promise(.success(data))
                } catch(let error) {
                    promise(.failure(error))
                }
            }
        }
    }
}

