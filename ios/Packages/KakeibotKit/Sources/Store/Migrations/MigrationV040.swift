import GRDB

enum MigrationV040 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "adjustment") { table in
            table.primaryKey("id", .text)
            table.column("wallet_id", .text).notNull().references("wallet")
            table.column("date", .text).notNull()
            table.column("amount", .integer).notNull().check { $0 != 0 }
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }

        try db.create(index: "adjustment_wallet_id", on: "adjustment", columns: ["wallet_id"])

        try MigrationV026.createTriggers(
            on: "adjustment",
            key: "id",
            recording: MigrationV028.recording,
            in: db
        )
    }
}
