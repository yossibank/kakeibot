import GRDB

enum MigrationV7 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "setting_new") { table in
            table.primaryKey("key", .text)
            table.column("value", .text).notNull()
        }

        try db.execute(
            sql: "INSERT INTO setting_new (key, value) SELECT key, value FROM setting"
        )

        try db.drop(table: "setting")
        try db.rename(table: "setting_new", to: "setting")
    }
}
