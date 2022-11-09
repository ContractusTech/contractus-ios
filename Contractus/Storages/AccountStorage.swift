//
//  KeychainService.swift
//  Contractus
//
//  Created by Simon Hudishkin on 25.07.2022.
//

import KeychainAccess
import Foundation

protocol AccountStorage {
    func getPrivateKey() -> Data?
    func savePrivateKey(_ privateKey: Data)
    func deletePrivateKey()
}


final class KeychainAccountStorage: AccountStorage {

    enum Keys: String {
        static let serviceKey = "app.me.Contractus.Account"
        case currentPrivateKey
    }

    private let keychain = Keychain(service: Keys.serviceKey)
    func getPrivateKey() -> Data? {
        return try? keychain.getData(Keys.currentPrivateKey.rawValue)
    }

    func savePrivateKey(_ privateKey: Data) {
        try? keychain.set(privateKey, key: Keys.currentPrivateKey.rawValue)
    }

    func deletePrivateKey() {
        try? keychain.remove(Keys.currentPrivateKey.rawValue)
    }

}
