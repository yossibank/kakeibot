import GRDB
@testable import Store
import Testing

struct MigrationV21Tests {
    @Test
    func addsEmptyLoanAmountToWallets() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v20")

        try queue.write { db in
            try db.execute(sql: Self.insertWallet)
        }

        try migrator.migrate(queue)

        let amounts = try queue.read { db in
            try Int?.fetchAll(db, sql: Self.selectAmounts)
        }

        #expect(amounts == [nil])
    }
}

private extension MigrationV21Tests {
    static let insertWallet = """
    INSERT INTO icon (id, emoji, color, created_at, updated_at)
    VALUES ('i', '💴', '#000000', '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z');
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, \
    sort_order, created_at, updated_at)
    VALUES ('w', '財布', 'cash', 'i', 0, 0, '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z')
    """

    static let selectAmounts = "SELECT loan_amount FROM wallet"
}
