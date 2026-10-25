import GRDB
@testable import Store
import Testing

struct MigrationV20Tests {
    @Test
    func dropsCustomizeCardClosed() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v19")

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

private extension MigrationV20Tests {
    static let insertSettings = """
    INSERT INTO setting (key, value) VALUES
    ('customize_card_closed', 'true'),
    ('text_size', 'standard')
    """

    static let selectKeys = "SELECT key FROM setting ORDER BY key"
}
