import GRDB

enum MigrationV028 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "category") { table in
            table.add(column: "wallet_id", .text).references("wallet")
        }

        try db.create(index: "category_wallet_id", on: "category", columns: ["wallet_id"])

        try db.create(table: "sync_share", options: .withoutRowID) { table in
            table.primaryKey("wallet_id", .text).references("wallet", onDelete: .cascade)
            table.column("owner_name", .text)
        }

        for (table, key) in MigrationV026.tables {
            try MigrationSyncTriggers.drop(on: table, in: db)
            try MigrationSyncTriggers.create(on: table, key: key, in: db)
        }
    }
}
