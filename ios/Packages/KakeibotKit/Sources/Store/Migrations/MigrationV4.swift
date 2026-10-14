import GRDB

enum MigrationV4 {}

extension MigrationV4 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "template") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()
            table.column("type", .text)
                .notNull()
                .check { ["expense", "income"].contains($0) }
            table.column("amount", .integer).check { $0 >= 1 }
            table.column("category_id", .text)
                .notNull()
                .references("category")
            table.column("wallet_id", .text).notNull().references("wallet")
            table.column("memo", .text)
            table.column("sort_order", .integer).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }
    }
}
