import GRDB

enum MigrationV032 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "sync_state") { table in
            table.add(column: "stop_reason", .text)
        }
    }
}
