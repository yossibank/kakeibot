import GRDB
@testable import Store
import Testing

struct MigrationV8Tests {
    @Test
    func ordersExistingRecurringsByDay() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v7")

        try queue.write { db in
            try db.execute(sql: Self.insertOwners)
            try db.execute(sql: Self.insertRecurrings)
        }

        try migrator.migrate(queue)

        let memos = try queue.read { db in
            try String.fetchAll(db, sql: Self.selectMemos)
        }

        #expect(memos == ["家賃", "動画", "保険"])
    }
}

private extension MigrationV8Tests {
    static let insertOwners = """
    INSERT INTO icon (id, emoji, color, created_at, updated_at)
    VALUES ('i', '💴', '#000000', '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z');
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, \
    sort_order, created_at, updated_at)
    VALUES ('w', '財布', 'cash', 'i', 0, 0, '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z');
    INSERT INTO category (id, kind, name, icon_id, sort_order, \
    created_at, updated_at)
    VALUES ('k', 'expense', '住まい', 'i', 0, '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z')
    """

    static let insertRecurrings = """
    INSERT INTO recurring (id, type, amount, category_id, wallet_id, memo, \
    frequency, day, start_date, created_at, updated_at) VALUES
    ('a', 'expense', 1, 'k', 'w', '保険', 'monthly', 27, '2026-01-01', \
    '2026-01-02T00:00:00Z', '2026-01-02T00:00:00Z'),
    ('b', 'expense', 1, 'k', 'w', '家賃', 'monthly', 5, '2026-01-01', \
    '2026-01-03T00:00:00Z', '2026-01-03T00:00:00Z'),
    ('c', 'expense', 1, 'k', 'w', '動画', 'monthly', 27, '2026-01-01', \
    '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
    """

    static let selectMemos = "SELECT memo FROM recurring ORDER BY sort_order"
}
