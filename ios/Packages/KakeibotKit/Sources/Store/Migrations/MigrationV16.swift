import GRDB

enum MigrationV16 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "valuation") { table in
            table.primaryKey("id", .text)
            table.column("wallet_id", .text).notNull().references("wallet")
            table.column("date", .text).notNull()
            table.column("amount", .integer).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
            table.uniqueKey(["wallet_id", "date"])
        }
    }
}
