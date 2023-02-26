//
//  SharedSecretTests.swift
//  ContractusTests
//
//  Created by Simon Hudishkin on 09.02.2023.
//

import XCTest
@testable import Contractus

class SharedSecretTests: XCTestCase {

    let privateKey = Data(repeating: 42, count: 64)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateSecret() async throws {

        let secret = try await SharedSecretService.createSharedSecret(privateKey: privateKey)
        let secretKey = try await SharedSecretService.recover(serverSecret: secret.serverSecret, clientSecret: secret.clientSecret, hashOriginalKey: secret.hashOriginalKey)
        assert(secretKey == secret.secretKey)

        let recoverSecret = try await SharedSecretService.encryptSharedSecretKey(base64String: secret.base64EncodedSecret, hashOriginalKey: secret.hashOriginalKey, privateKey: privateKey)

        assert(recoverSecret.secretKey == secret.secretKey)
        assert(recoverSecret.clientSecret == secret.clientSecret)
        assert(recoverSecret.serverSecret == secret.serverSecret)

        let recoveredByClientKey = try await SharedSecretService.recover(serverSecret: secret.serverSecret, clientSecret: secret.clientSecret, hashOriginalKey: secret.hashOriginalKey)

        assert(recoveredByClientKey == secret.secretKey)

    }

}
