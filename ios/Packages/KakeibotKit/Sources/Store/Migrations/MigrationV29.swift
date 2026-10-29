import GRDB

enum MigrationV29 {
    static func migrate(_ db: Database) throws {
        try db.rename(table: "sync_record", to: "sync_record_old")

        try db.create(table: "sync_record", options: .withoutRowID) { table in
            table.column("table_name", .text).notNull()
            table.column("record_id", .text).notNull()
            table.column("zone_name", .text).notNull()
            table.column("system_fields", .blob).notNull()
            table.primaryKey(["table_name", "record_id", "zone_name"])
        }

        try db.execute(sql: """
        INSERT INTO sync_record (table_name, record_id, zone_name, system_fields)
        SELECT table_name, record_id, 'Kakeibot', system_fields FROM sync_record_old
        """)

        try db.drop(table: "sync_record_old")
    }
}
