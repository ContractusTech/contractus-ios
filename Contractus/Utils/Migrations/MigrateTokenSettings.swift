//
//  MigrateTokenSettings.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.12.2023.
//

import Foundation

struct MigrateTokenSettings: MigrationItem {
    var needMigrate: Bool {
        guard let tokens = OldUtilsStorage.shared.getTokenSettings() else {
            return false
        }
        return !tokens.isEmpty
    }

    func migrate() {
        guard let tokens = OldUtilsStorage.shared.getTokenSettings() else { return }
        UtilsStorage.shared.saveTokenSettings(tokens: tokens, blockchain: .solana)
        OldUtilsStorage.shared.clear()
    }

}
