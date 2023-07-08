//
//  DealStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.09.2022.
//

import Foundation

import KeychainAccess
import Foundation

protocol SharedSecretStorage {
    func getSharedSecret(for dealId: String) -> Data?
    func saveSharedSecret(for dealId: String, sharedSecret: Data) throws
    func deleteSharedSecret(for dealId: String) throws
}

fileprivate let SERVICE = "\(Bundle.main.bundleIdentifier!).SharedSecret"
fileprivate let KEY_FORMAT = "sharedSecret.deal_%@"

final class SharedSecretStorageImpl: SharedSecretStorage {

    private let keychain = Keychain(service: SERVICE)
        .synchronizable(true)

    func getSharedSecret(for dealId: String) -> Data? {
        return try? keychain.getData(getKey(dealId))
    }

    func saveSharedSecret(for dealId: String, sharedSecret: Data) throws {
        try keychain.set(sharedSecret, key: getKey(dealId))
    }

    func deleteSharedSecret(for dealId: String) throws {
        try keychain.remove(getKey(dealId))
    }

    private func getKey(_ value: String) -> String {
        String(format: KEY_FORMAT, value)
    }

}
