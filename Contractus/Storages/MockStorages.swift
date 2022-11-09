//
//  MockStorages.swift
//  Contractus
//
//  Created by Simon Hudishkin on 31.07.2022.
//

import Foundation


class MockAccountStorage: AccountStorage {
    func getPrivateKey() -> Data? {
        return nil
    }

    func savePrivateKey(_ privateKey: Data) {

    }

    func deletePrivateKey() {
        
    }
}
