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
        
        let migrateItems = migrationItems.filter { $0.needMigrate }

        guard !migrateItems.isEmpty else {
            debugPrint("[MigrationManager] - No migration")
            return
        }

        for item in migrateItems  {
            item.migrate()
        }

        debugPrint("[MigrationManager] - Finish migrate (\(migrateItems.count))")
    }
}
