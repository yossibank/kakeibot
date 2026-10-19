import GRDB

enum MigrationV10 {}

extension MigrationV10 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "template") { table in
            table.add(column: "archived_at", .text)
        }

        try db.alter(table: "recurring") { table in
            table.add(column: "archived_at", .text)
        }
    }
}
