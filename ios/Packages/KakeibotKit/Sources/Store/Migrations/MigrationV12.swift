import GRDB

enum MigrationV12 {}

extension MigrationV12 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "holiday_shift", .text)
                .notNull()
                .defaults(to: "none")
        }
    }
}
