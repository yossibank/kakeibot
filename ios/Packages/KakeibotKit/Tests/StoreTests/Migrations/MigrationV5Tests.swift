import Core
import GRDB
@testable import Store
import Testing

struct MigrationV5Tests {
    @Test
    func keepsEntriesWithoutTag() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v4")

        try queue.write { db in
            try db.execute(sql: Self.insertIcon)
            try db.execute(sql: Self.insertWallet)
            try db.execute(sql: Self.insertCategory)
            try db.execute(sql: Self.insertEntry)
        }

        try migrator.migrate(queue)

        let entry = try queue.read { db in
            try Entry.fetchOne(db, key: Self.entryId)
        }

        let tags = try queue.read { db in
            try EntryTag.fetchCount(db)
        }

        #expect(entry?.amount == 980)
        #expect(entry?.tagId == nil)
        #expect(tags == 0)
    }
}

private extension MigrationV5Tests {
    static let entryId = "40000000-0000-4000-8000-000000000001"

    static let insertIcon = """
    INSERT INTO icon (id, glyph, color, created_at, updated_at)
    VALUES ('10000000-0000-4000-8000-000000000001', 'food', '#000000',
    '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """

    static let insertWallet = """
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, sort_order, created_at, updated_at)
    VALUES ('20000000-0000-4000-8000-000000000001', '財布', 'cash',
    '10000000-0000-4000-8000-000000000001', 0, 0,
    '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """

    static let insertCategory = """
    INSERT INTO category (id, kind, name, icon_id, sort_order, created_at, updated_at)
    VALUES ('30000000-0000-4000-8000-000000000001', 'expense', '食費',
    '10000000-0000-4000-8000-000000000001', 0,
    '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """

    static let insertEntry = """
    INSERT INTO entry (id, type, amount, date, category_id, wallet_id, created_at, updated_at)
    VALUES ('40000000-0000-4000-8000-000000000001', 'expense', 980, '2026-10-12',
    '30000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """
}
