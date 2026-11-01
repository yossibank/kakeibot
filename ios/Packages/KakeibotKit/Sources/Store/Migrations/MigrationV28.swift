import GRDB

enum MigrationV28 {
    static let recording = """
    (SELECT (enabled OR EXISTS (SELECT 1 FROM sync_share)) AND NOT applying FROM sync_state)
    """

    static func migrate(_ db: Database) throws {
        try db.alter(table: "category") { table in
            table.add(column: "wallet_id", .text).references("wallet")
        }

        try db.create(index: "category_wallet_id", on: "category", columns: ["wallet_id"])

        try db.create(table: "sync_share", options: .withoutRowID) { table in
            table.primaryKey("wallet_id", .text).references("wallet", onDelete: .cascade)
            table.column("owner_name", .text)
        }

        for (table, key) in MigrationV26.tables {
            for (name, _, _) in MigrationV26.events {
                try db.execute(sql: "DROP TRIGGER sync_\(table)_\(name)")
            }

            try MigrationV26.createTriggers(on: table, key: key, recording: recording, in: db)
        }
    }
}
