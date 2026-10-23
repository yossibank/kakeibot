import GRDB
@testable import Store
import Testing

struct MigrationV19Tests {
    @Test
    func dropsCharacterSettings() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v18")

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

private extension MigrationV19Tests {
    static let insertSettings = """
    INSERT INTO setting (key, value) VALUES
    ('character_id', 'cat'),
    ('character_name', 'ミケ'),
    ('text_size', 'standard')
    """

    static let selectKeys = "SELECT key FROM setting ORDER BY key"
}
