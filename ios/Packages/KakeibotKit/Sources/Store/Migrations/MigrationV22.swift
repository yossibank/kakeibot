import GRDB

enum MigrationV22 {
    static func migrate(_ db: Database) throws {
        try db.execute(sql: "DELETE FROM setting WHERE key = 'category_menu_opened'")
    }
}
