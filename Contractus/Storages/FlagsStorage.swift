//
//  FlagsStorage.swift
//  Contractus
//
//  Created by Simon Hudishkin on 13.05.2023.
//

import Foundation


final class FlagsStorage {

    private enum Keys: String {
        case mainTokensVisibility, onboardingPresented, changelogId
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
    
    var onboardingPresented: Bool {
        get {
            storage.bool(forKey: Keys.onboardingPresented.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.onboardingPresented.rawValue)
        }
    }
    
    var changelogId: Int {
        get {
            storage.integer(forKey: Keys.changelogId.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.changelogId.rawValue)
        }
    }
}
