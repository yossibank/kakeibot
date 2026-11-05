import GRDB
@testable import Store
import Testing

struct MigrationV039Tests {
    @Test
    func addsFinalAmountAsEmpty() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v38")
        try migrator.migrate(queue)

        let column = try queue.read { db in
            try db.columns(in: "recurring").first { $0.name == "final_amount" }
        }

        #expect(column != nil)
        #expect(column?.isNotNull == false)
    }
}
