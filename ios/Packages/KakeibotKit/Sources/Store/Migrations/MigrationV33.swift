import GRDB

enum MigrationV33 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "sync_state") { table in
            table.add(column: "send_problem", .text)
        }
    }
}
