import GRDB

enum MigrationV3 {}

extension MigrationV3 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "new_icon") { table in
            table.primaryKey("id", .text)
            table.column("emoji", .text)
            table.column("text", .text).check { length($0) <= 3 }
            table.column("glyph", .text)
            table.column("color", .text).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
            let hasLook = "emoji IS NOT NULL OR text IS NOT NULL OR glyph IS NOT NULL"
            table.check(sql: hasLook)
        }

        try db.execute(sql: copyIcons)
        try db.drop(table: "icon")
        try db.rename(table: "new_icon", to: "icon")
    }
}

private extension MigrationV3 {
    static let copyIcons = """
    INSERT INTO new_icon (id, emoji, text, glyph, color, created_at, updated_at)
    SELECT id, emoji, text, glyph, color, created_at, updated_at FROM icon
    """
}
