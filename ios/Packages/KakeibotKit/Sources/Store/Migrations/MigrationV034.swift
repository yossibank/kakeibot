import GRDB

enum MigrationV034 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "sync_state") { table in
            table.add(column: "fetching", .boolean).notNull().defaults(to: false)
            table.add(column: "synced_at", .datetime)
        }
    }
}
