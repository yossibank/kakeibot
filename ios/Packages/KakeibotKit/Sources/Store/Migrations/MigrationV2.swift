import Core
import GRDB

enum MigrationV2 {}

extension MigrationV2 {
    static func migrate(_ db: Database) throws {
        try db.create(table: "new_icon") { table in
            table.primaryKey("id", .text)
            table.column("emoji", .text)
            table.column("text", .text).check { length($0) <= 3 }
            table.column("glyph", .text).check { glyphNames.contains($0) }
            table.column("color", .text).notNull()
            table.column("created_at", .text).notNull()
            table.column("updated_at", .text).notNull()
            let hasLook = "emoji IS NOT NULL OR text IS NOT NULL OR glyph IS NOT NULL"
            table.check(sql: hasLook)
        }

        try db.execute(sql: copyIcons)
        try db.drop(table: "icon")
        try db.rename(table: "new_icon", to: "icon")

        for (emoji, glyph) in defaultGlyphs {
            try db.execute(
                sql: "UPDATE icon SET glyph = ?, emoji = NULL WHERE emoji = ?",
                arguments: [glyph, emoji]
            )
        }
    }
}

private extension MigrationV2 {
    static let glyphNames = [
        "food", "daily", "transit", "social", "hobby", "clothes", "beauty",
        "medical", "home", "phone", "utility", "salary", "bonus", "other",
        "cash", "bank"
    ]

    static let copyIcons = """
    INSERT INTO new_icon (id, emoji, text, glyph, color, created_at, updated_at)
    SELECT id, emoji, text, NULL, color, created_at, updated_at FROM icon
    """

    static let defaultGlyphs: [(String, Icon.Glyph)] = [
        ("🍙", .food),
        ("🧻", .daily),
        ("🚃", .transit),
        ("🍻", .social),
        ("🎮", .hobby),
        ("👕", .clothes),
        ("💄", .beauty),
        ("💊", .medical),
        ("🏠", .home),
        ("📱", .phone),
        ("💡", .utility),
        ("📦", .other),
        ("💴", .salary),
        ("🎁", .bonus),
        ("✨", .other),
        ("👛", .cash),
        ("🏦", .bank)
    ]
}
