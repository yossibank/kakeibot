import GRDB

enum MigrationV027 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "sync_record", options: .withoutRowID) { table in
            table.column("table_name", .text).notNull()
            table.column("record_id", .text).notNull()
            table.column("system_fields", .blob).notNull()
            table.primaryKey(["table_name", "record_id"])
        }
    }
}
