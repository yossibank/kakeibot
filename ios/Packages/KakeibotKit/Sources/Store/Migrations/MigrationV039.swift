import GRDB

enum MigrationV039 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "final_amount", .integer)
        }
    }
}
