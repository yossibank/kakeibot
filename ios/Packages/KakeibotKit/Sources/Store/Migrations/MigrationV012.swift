import GRDB

enum MigrationV012 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "holiday_shift", .text).notNull().defaults(to: "none")
        }
    }
}
