import GRDB

enum MigrationV044 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "review_comment") { table in
            table.drop(column: "suggestion")
            table.drop(column: "breakdown")
        }
    }
}
