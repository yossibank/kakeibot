import GRDB

enum MigrationV30 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "sync_state") { table in
            table.add(column: "shared_engine_state", .blob)
        }
    }
}
