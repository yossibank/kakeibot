import Core
import GRDB
@testable import Store
import Testing

struct MigrationV043Tests {
    @Test
    func keepsSavedCommentsAndAddsEmptyGoals() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator

        try migrator.migrate(queue, upTo: "v42")
        try queue.write { db in
            try db.execute(sql: Self.insertComment)
        }
        try migrator.migrate(queue)

        let comment = try queue.read { db in
            try ReviewComment.fetchOne(db, key: "month:2026-11-01")
        }
        let goals = try queue.read { db in
            try ReviewGoal.fetchAll(db)
        }

        #expect(comment != nil)
        #expect(goals.isEmpty)
    }
}

private extension MigrationV043Tests {
    static let insertComment = """
    INSERT INTO review_comment (period, body, suggestion, basis, created_at)
    VALUES ('month:2026-11-01', '食費が増えています。', '控えめにします。', '食費', '2026-11-18T00:00:00Z')
    """
}
