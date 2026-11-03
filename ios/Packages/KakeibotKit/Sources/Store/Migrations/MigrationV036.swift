import GRDB

enum MigrationV036 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "entry_item") { table in
            table.add(column: "tax_rate", .integer).check { $0 == nil || [8, 10].contains($0) }
        }
    }
}
