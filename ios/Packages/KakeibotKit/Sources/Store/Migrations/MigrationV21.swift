import GRDB

enum MigrationV21 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "wallet") { table in
            table.add(column: "loan_amount", .integer)
        }
    }
}
