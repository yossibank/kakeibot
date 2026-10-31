import Core
import GRDB

public extension AppDatabase {
    func entryHistory() async throws -> EntryHistory {
        try await writer.read { db in
            let count = try Entry.fetchCount(db)
            let first = try Entry.order(Column("created_at")).fetchOne(db)

            return EntryHistory(count: count, firstCreatedAt: first?.createdAt)
        }
    }
}
