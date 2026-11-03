import GRDB

enum MigrationV019 {
    static func migrate(_ db: Database) throws {
        try db.execute(
            sql: """
            DELETE FROM setting
            WHERE key IN ('character_id', 'character_name')
            """
        )
    }
}
