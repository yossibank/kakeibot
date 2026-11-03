import GRDB
@testable import Store
import Testing

struct MigrationV023Tests {
    @Test
    func addsEmptyTransferIdToEntries() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v22")

        try queue.write { db in
            try db.execute(sql: Self.insertEntry)
        }

        try migrator.migrate(queue)

        let transfers = try queue.read { db in
            try String?.fetchAll(db, sql: Self.selectTransfers)
        }

        #expect(transfers == [nil])
    }
}

private extension MigrationV023Tests {
    static let insertEntry = """
    INSERT INTO icon (id, emoji, color, created_at, updated_at)
    VALUES ('i', '💴', '#000000', '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z');
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, \
    sort_order, created_at, updated_at)
    VALUES ('w', '財布', 'cash', 'i', 0, 0, '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z'), \
    ('b', '銀行', 'bank', 'i', 0, 1, '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z');
    INSERT INTO entry (id, type, amount, date, wallet_id, to_wallet_id, \
    created_at, updated_at)
    VALUES ('e', 'transfer', 1000, '2026-01-01', 'b', 'w', \
    '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
    """

    static let selectTransfers = "SELECT transfer_id FROM entry"
}
