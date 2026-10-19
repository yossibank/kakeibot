import GRDB
@testable import Store
import Testing

struct MigrationV11Tests {
    @Test
    func keepsLatestStampPerDay() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v10")

        try queue.write { db in
            try db.execute(sql: Self.insertIcon)
            try db.execute(sql: Self.insertStamps)
        }

        try migrator.migrate(queue)

        let ids = try queue.read { db in
            try String.fetchAll(db, sql: Self.selectIds)
        }

        #expect(ids == ["b", "c"])
        #expect(throws: DatabaseError.self) {
            try queue.write { db in
                try db.execute(sql: Self.insertDuplicate)
            }
        }
    }
}

private extension MigrationV11Tests {
    static let insertIcon = """
    INSERT INTO icon (id, emoji, color, created_at, updated_at)
    VALUES ('i', '⭐️', '#000000', '2026-01-01T00:00:00Z', \
    '2026-01-01T00:00:00Z')
    """

    static let insertStamps = """
    INSERT INTO calendar_stamp (id, date, icon_id, created_at) VALUES
    ('a', '2026-10-01', 'i', '2026-10-01T09:00:00Z'),
    ('b', '2026-10-01', 'i', '2026-10-01T10:00:00Z'),
    ('c', '2026-10-02', 'i', '2026-10-02T09:00:00Z')
    """

    static let insertDuplicate = """
    INSERT INTO calendar_stamp (id, date, icon_id, created_at)
    VALUES ('d', '2026-10-02', 'i', '2026-10-02T11:00:00Z')
    """

    static let selectIds = "SELECT id FROM calendar_stamp ORDER BY id"
}
