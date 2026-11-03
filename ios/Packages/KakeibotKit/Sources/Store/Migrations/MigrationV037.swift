import GRDB

enum MigrationV037 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "entry") { table in
            table.add(column: "tax_included", .boolean).notNull().defaults(to: false)
        }
    }
}
