import GRDB

enum MigrationV017 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "entry") { table in
            table.add(column: "bill_month", .text)
        }
    }
}
