import GRDB

enum MigrationV5 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "tag") { table in
            table.primaryKey("id", .text)
            table.column("category_id", .text)
                .notNull()
                .references("category")
            table.column("name", .text).notNull()
            table.column("sort_order", .integer).notNull()
            table.column("archived_at", .text)
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }

        try db.alter(table: "entry") { table in
            table.add(column: "tag_id", .text).references("tag")
        }

        try db.alter(table: "template") { table in
            table.add(column: "tag_id", .text).references("tag")
        }
    }
}
