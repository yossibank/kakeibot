import GRDB
@testable import Store
import Testing

struct MigrationV037Tests {
    @Test
    func addsTaxIncludedAsExclusiveByDefault() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v36")
        try migrator.migrate(queue)

        let column = try queue.read { db in
            try db.columns(in: "entry").first { $0.name == "tax_included" }
        }

        #expect(column?.isNotNull == true)
        #expect(column?.defaultValueSQL == "0")
    }
}
