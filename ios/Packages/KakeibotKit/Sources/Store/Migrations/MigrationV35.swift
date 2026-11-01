import GRDB

enum MigrationV35 {
    static let tables = [
        ("entry_item", "id"),
        ("item_name", "id")
    ]

    static func migrate(_ db: Database) throws {
        try db.create(table: "entry_item") { table in
            table.primaryKey("id", .text)
            table.column("entry_id", .text).notNull().references("entry", onDelete: .cascade)
            table.column("name", .text).notNull().check { length($0) > 0 }
            table.column("quantity", .integer).notNull().check { $0 >= 1 }
            table.column("amount", .integer).notNull()
            table.column("sort_order", .integer).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }

        try db.create(index: "entry_item_entry_id", on: "entry_item", columns: ["entry_id"])

        try db.create(table: "item_name") { table in
            table.primaryKey("id", .text)
            table.column("store", .text).notNull()
            table.column("raw", .text).notNull()
            table.column("name", .text).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
            table.uniqueKey(["store", "raw"])
        }

        for (table, key) in tables {
            try MigrationV26.createTriggers(
                on: table,
                key: key,
                recording: MigrationV28.recording,
                in: db
            )
        }
    }
}
