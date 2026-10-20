import GRDB

enum MigrationV14 {}

extension MigrationV14 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "recurring") { table in
            table.add(column: "pays_after_closings", .integer)
                .notNull()
                .defaults(to: 1)
                .check { (1...2).contains($0) }
        }
    }
}
