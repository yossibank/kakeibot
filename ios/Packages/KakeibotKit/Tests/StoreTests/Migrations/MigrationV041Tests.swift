import GRDB
@testable import Store
import Testing

struct MigrationV041Tests {
    @Test
    func createsReviewCommentTable() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v40")
        try migrator.migrate(queue, upTo: "v41")

        let columns = try queue.read { db in
            try db.columns(in: "review_comment").map(\.name)
        }

        #expect(columns == ["period", "body", "suggestion", "basis", "created_at"])
    }

    @Test
    func doesNotRecordChangesWhileSyncing() throws {
        let queue = try DatabaseQueue()
        try AppDatabase.migrator.migrate(queue, upTo: "v41")

        let count = try queue.write { db in
            try db.execute(sql: "UPDATE sync_state SET enabled = 1")
            try db.execute(sql: Self.insertComment)

            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM sync_change")
        }

        #expect(count == 0)
    }
}

private extension MigrationV041Tests {
    static let insertComment = """
    INSERT INTO review_comment (period, body, suggestion, basis, created_at)
    VALUES ('month:2026-11-01', '食費が増えています。', '控えめにします。', '食費', 'x')
    """
}
