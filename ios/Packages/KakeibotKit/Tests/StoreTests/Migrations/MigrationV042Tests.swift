import GRDB
@testable import Store
import Testing

struct MigrationV042Tests {
    @Test
    func addsBreakdownToSavedComments() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v41")
        try queue.write { db in
            try db.execute(sql: Self.insertComment)
        }
        try migrator.migrate(queue, upTo: "v42")

        let row = try queue.read { db in
            try Row.fetchOne(db, sql: "SELECT body, breakdown FROM review_comment")
        }

        #expect(row?["body"] == "食費が増えています。")
        #expect(row?["breakdown"] == DatabaseValue.null)
    }
}

private extension MigrationV042Tests {
    static let insertComment = """
    INSERT INTO review_comment (period, body, suggestion, basis, created_at)
    VALUES ('month:2026-11-01', '食費が増えています。', '控えめにします。', '食費', '2026-11-18T00:00:00Z')
    """
}
