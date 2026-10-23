import GRDB

enum MigrationV9 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "shelf_icon") { table in
            table.primaryKey("id", .text)
            table.column("icon_id", .text).notNull().references("icon")
            table.column("sort_order", .integer).notNull()
            table.column("archived_at", .text)
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
        }
    }
}
