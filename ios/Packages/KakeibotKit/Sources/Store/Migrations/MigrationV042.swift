import GRDB

enum MigrationV042 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "review_comment") { table in
            table.add(column: "breakdown", .text)
        }
    }
}
