import Core
import GRDB

public extension AppDatabase {
    func entryHistory() async throws -> EntryHistory {
        try await writer.read(Self.entryHistory)
    }
}

extension AppDatabase {
    static func entryHistory(in db: Database) throws -> EntryHistory {
        let count = try Entry.fetchCount(db)
        let first = try Entry.order(Column("created_at")).fetchOne(db)
        return EntryHistory(count: count, firstCreatedAt: first?.createdAt)
    }
}
