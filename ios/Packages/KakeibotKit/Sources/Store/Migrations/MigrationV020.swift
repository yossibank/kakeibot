import GRDB

enum MigrationV020 {
    static func migrate(_ db: Database) throws {
        try db.execute(sql: "DELETE FROM setting WHERE key = 'customize_card_closed'")
    }
}
