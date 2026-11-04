import GRDB
@testable import Store
import Testing

struct MigrationV038Tests {
    @Test(arguments: ["template", "recurring"])
    func addsBillShiftAsUsualByDefault(table: String) throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v37")
        try migrator.migrate(queue)

        let column = try queue.read { db in
            try db.columns(in: table).first { $0.name == "bill_shift" }
        }

        #expect(column?.isNotNull == true)
        #expect(column?.defaultValueSQL == "0")
    }
}
