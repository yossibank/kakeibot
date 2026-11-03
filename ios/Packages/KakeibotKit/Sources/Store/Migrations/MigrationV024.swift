import GRDB

enum MigrationV024 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "fee", .integer)
        }
    }
}
