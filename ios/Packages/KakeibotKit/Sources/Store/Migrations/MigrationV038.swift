import GRDB

enum MigrationV038 {
    static func migrate(_ db: Database) throws {
        for table in ["template", "recurring"] {
            try db.alter(table: table) { table in
                table.add(column: "bill_shift", .integer).notNull().defaults(to: 0)
            }
        }
    }
}
