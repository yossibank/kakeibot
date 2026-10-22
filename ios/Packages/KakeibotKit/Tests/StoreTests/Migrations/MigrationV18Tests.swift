import GRDB
@testable import Store
import Testing

struct MigrationV18Tests {
    @Test
    func dropsOpenHiddenLists() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v17")

        try queue.write { db in
            try db.execute(sql: Self.insertSettings)
        }

        try migrator.migrate(queue)

        let keys = try queue.read { db in
            try String.fetchAll(db, sql: Self.selectKeys)
        }

        #expect(keys == ["text_size"])
    }
}

private extension MigrationV18Tests {
    static let insertSettings = """
    INSERT INTO setting (key, value) VALUES
    ('open_hidden_lists', 'categories'),
    ('text_size', 'standard')
    """

    static let selectKeys = "SELECT key FROM setting ORDER BY key"
}
