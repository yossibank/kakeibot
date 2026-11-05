import GRDB
@testable import Store
import Testing

struct MigrationV040Tests {
    @Test
    func createsAdjustmentTable() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v39")
        try migrator.migrate(queue)

        let columns = try queue.read { db in
            try db.columns(in: "adjustment").map(\.name)
        }

        #expect(columns == ["id", "wallet_id", "date", "amount", "created_at", "updated_at"])
    }

    @Test
    func rejectsZeroAmount() throws {
        let queue = try DatabaseQueue()
        try AppDatabase.migrator.migrate(queue)

        let rejected = try queue.write { db in
            try db.execute(sql: Self.insertWallet)

            do {
                try db.execute(sql: Self.insertAdjustment, arguments: [0])
                return false
            } catch {
                return true
            }
        }

        #expect(rejected)
    }

    @Test
    func recordsChangesWhileSyncing() throws {
        let queue = try DatabaseQueue()
        try AppDatabase.migrator.migrate(queue)

        let count = try queue.write { db in
            try db.execute(sql: Self.insertWallet)
            try db.execute(sql: "UPDATE sync_state SET enabled = 1")
            try db.execute(sql: Self.insertAdjustment, arguments: [-300])

            return try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM sync_change WHERE table_name = 'adjustment'"
            )
        }

        #expect(count == 1)
    }
}

private extension MigrationV040Tests {
    static let insertWallet = """
    INSERT INTO icon (id, emoji, color, created_at, updated_at)
    VALUES ('i1', '👛', '#000000', 'x', 'x');
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, sort_order, created_at, updated_at)
    VALUES ('w1', '財布', 'cash', 'i1', 0, 0, 'x', 'x');
    """

    static let insertAdjustment = """
    INSERT INTO adjustment (id, wallet_id, date, amount, created_at, updated_at)
    VALUES ('a1', 'w1', '2026-10-23', ?, 'x', 'x')
    """
}
