import GRDB

enum MigrationV24 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "fee", .integer)
        }
    }
}
