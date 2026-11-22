import GRDB
@testable import Store
import Testing

struct MigrationV044Tests {
    @Test
    func dropsSuggestionAndBreakdownKeepingValues() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v43")
        try queue.write { db in
            try db.execute(sql: Self.insertComment)
        }
        try migrator.migrate(queue)

        let columns = try queue.read { db in
            try db.columns(in: "review_comment").map(\.name)
        }
        let body = try queue.read { db in
            try String.fetchOne(db, sql: "SELECT body FROM review_comment")
        }
        let basis = try queue.read { db in
            try String.fetchOne(db, sql: "SELECT basis FROM review_comment")
        }
        let createdAt = try queue.read { db in
            try String.fetchOne(db, sql: "SELECT created_at FROM review_comment")
        }

        #expect(columns == ["period", "body", "basis", "created_at"])
        #expect(body == "食費が増えています。")
        #expect(basis == "食費")
        #expect(createdAt == "2026-11-18T00:00:00Z")
    }
}

private extension MigrationV044Tests {
    static let insertComment = """
    INSERT INTO review_comment (period, body, suggestion, basis, created_at)
    VALUES ('month:2026-11-01', '食費が増えています。', '控えめにします。', '食費', '2026-11-18T00:00:00Z')
    """
}
