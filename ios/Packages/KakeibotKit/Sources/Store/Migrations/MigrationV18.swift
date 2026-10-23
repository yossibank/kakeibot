import GRDB

enum MigrationV18 {
    static func migrate(_ db: Database) throws {
        try db.execute(
            sql: "DELETE FROM setting WHERE key = 'open_hidden_lists'"
        )
    }
}
