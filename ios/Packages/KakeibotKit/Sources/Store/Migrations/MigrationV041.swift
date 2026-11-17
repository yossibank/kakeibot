import GRDB

enum MigrationV041 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "review_comment") { table in
            table.primaryKey("period", .text)
            table.column("body", .text).notNull()
            table.column("suggestion", .text).notNull()
            table.column("basis", .text).notNull()
            table.column("created_at", .text).notNull()
        }
    }
}
