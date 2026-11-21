import GRDB

enum MigrationV043 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "review_goal") { table in
            table.primaryKey("id", .text)
            table.column("period", .text).notNull().indexed()
            table.column("kind", .text).notNull()
            table.column("category_id", .text).references("category", onDelete: .cascade)
            table.column("memo", .text)
            table.column("baseline", .integer).notNull()
            table.column("target", .integer).notNull()
            table.column("saving", .integer).notNull()
            table.column("result", .integer)
            table.column("saved", .integer)
            table.column("created_at", .text).notNull()
            table.column("checked_at", .text)
        }
    }
}
