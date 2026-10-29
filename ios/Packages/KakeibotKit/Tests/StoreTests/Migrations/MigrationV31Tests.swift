import GRDB
@testable import Store
import Testing

struct MigrationV31Tests {
    @Test
    func indexesEntryLookups() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v30")
        try migrator.migrate(queue)

        let indexes = try queue.read { db in
            try db.indexes(on: "entry").map(\.columns)
        }

        let plan = try queue.read { db in
            try Row.fetchAll(db, sql: Self.datePlan).map { $0["detail"] as String }
        }

        #expect(indexes.contains(["date"]))
        #expect(indexes.contains(["wallet_id", "date"]))
        #expect(indexes.contains(["to_wallet_id"]))
        #expect(indexes.contains(["category_id"]))
        #expect(plan.contains { $0.contains("entry_date") })
    }
}

private extension MigrationV31Tests {
    static let datePlan = "EXPLAIN QUERY PLAN SELECT * FROM entry WHERE date >= '2026-10-01'"
}
