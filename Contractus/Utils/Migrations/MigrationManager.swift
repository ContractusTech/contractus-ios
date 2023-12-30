//
//  Migrations.swift
//  Contractus
//
//  Created by Simon Hudishkin on 20.12.2023.
//

import Foundation

protocol MigrationItem {
    var needMigrate: Bool { get }

    func migrate()
}

enum MigrationManager {

    private static let migrationItems: [MigrationItem] = [
        MigrateTokenSettings()
        // Put here
    ]

    static func migrateIfNeeded() {
        
        guard !migrationItems.isEmpty else {
            debugPrint("[MigrationManager] - No migration")
            return
        }

        let migrateItems = Self.migrationItems.filter { $0.needMigrate }
        for item in migrateItems  {
            item.migrate()
        }

        debugPrint("[MigrationManager] - Finish migrate (\(migrateItems.count))")
    }
}
