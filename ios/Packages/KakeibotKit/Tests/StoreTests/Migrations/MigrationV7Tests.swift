import GRDB
@testable import Store
import Testing

struct MigrationV7Tests {
    @Test
    func keepsSettingsAndAcceptsAnyKey() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v6")

        try queue.write { db in
            try db.execute(sql: Self.insertStartDay)
        }

        try migrator.migrate(queue)

        try queue.write { db in
            try db.execute(sql: Self.insertUnknown)
        }

        let values = try queue.read { db in
            try String.fetchAll(db, sql: Self.selectValues)
        }

        #expect(values == ["25", "later"])
    }
}

private extension MigrationV7Tests {
    static let insertStartDay = """
    INSERT INTO setting (key, value) VALUES ('month_start_day', '25')
    """

    static let insertUnknown = """
    INSERT INTO setting (key, value) VALUES ('future_setting', 'later')
    """

    static let selectValues = "SELECT value FROM setting ORDER BY value"
}
