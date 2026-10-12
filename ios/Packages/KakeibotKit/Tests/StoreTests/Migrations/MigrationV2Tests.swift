import Core
import GRDB
@testable import Store
import Testing

struct MigrationV2Tests {
    @Test
    func replacesDefaultEmojiWithGlyphs() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v1")

        try queue.write { db in
            try db.execute(sql: Self.insertIcon, arguments: [Self.foodIcon, "🍙"])
            try db.execute(sql: Self.insertIcon, arguments: [Self.customIcon, "🎯"])
            try db.execute(sql: Self.insertWallet, arguments: [Self.foodIcon])
        }

        try migrator.migrate(queue)
        let food = try queue.read { try Icon.fetchOne($0, key: Self.foodIcon) }
        let custom = try queue.read { try Icon.fetchOne($0, key: Self.customIcon) }
        let brokenReferences = try queue.read { try Array($0.foreignKeyViolations()) }

        #expect(food?.glyph == .food)
        #expect(food?.emoji == nil)
        #expect(custom?.glyph == nil)
        #expect(custom?.emoji == "🎯")
        #expect(brokenReferences.isEmpty)
    }
}

private extension MigrationV2Tests {
    static let foodIcon = "10000000-0000-4000-8000-000000000001"
    static let customIcon = "10000000-0000-4000-8000-000000000002"

    static let insertIcon = """
    INSERT INTO icon (id, emoji, text, color, created_at, updated_at)
    VALUES (?, ?, NULL, '#000000', '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """

    static let insertWallet = """
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, sort_order, created_at, updated_at)
    VALUES ('20000000-0000-4000-8000-000000000001', '財布', 'cash', ?, 0, 0,
    '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """
}
