import GRDB
@testable import Store
import Testing

struct AppDatabaseTests {
    @Test
    func createsEveryTable() throws {
        let database = try AppDatabase.inMemory()
        let tables = try database.writer.read { db in
            try String.fetchSet(db, sql: Self.tableQuery)
        }

        #expect(tables == Self.tables)
    }

    @Test
    func completesEveryMigration() throws {
        let database = try AppDatabase.inMemory()
        let migrator = AppDatabase.migrator
        let completed = try database.writer.read { db in
            try migrator.hasCompletedMigrations(db)
        }

        #expect(completed)
    }
}

private extension AppDatabaseTests {
    static let tableQuery = """
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'grdb_%'
    """

    static let tables: Set = [
        "budget",
        "calendar_stamp",
        "category",
        "entry",
        "icon",
        "no_spend_day",
        "recurring",
        "reward_goal",
        "reward_log",
        "reward_rule",
        "setting",
        "shelf_icon",
        "tag",
        "template",
        "theme",
        "valuation",
        "wallet"
    ]
}
