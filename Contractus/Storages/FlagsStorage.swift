//
//  FlagsStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 13.05.2023.
//

import Foundation


final class FlagsStorage {

    private enum Keys: String {
        case mainTokensVisibility
    }

    static let shared = FlagsStorage()

    private var storage = UserDefaults.standard

    var mainTokensVisibility: Bool {
        get {
            storage.bool(forKey: Keys.mainTokensVisibility.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.mainTokensVisibility.rawValue)
        }
    }
}
