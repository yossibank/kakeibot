import GRDB

enum MigrationV018 {
    static func migrate(_ db: Database) throws {
        try db.execute(sql: "DELETE FROM setting WHERE key = 'open_hidden_lists'")
    }
}
