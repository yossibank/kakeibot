import Core
import GRDB

public extension AppDatabase {
    func entryHistory() async throws -> EntryHistory {
        try await writer.read(Self.entryHistory)
    }

    func claimReviewRequest(
        version: String,
        when isReady: @escaping @Sendable (EntryHistory) -> Bool
    ) async throws -> Bool {
        try await writer.write { db in
            guard try Self.setting(.reviewRequestedVersion, in: db) != version else {
                return false
            }

            guard try isReady(Self.entryHistory(in: db)) else {
                return false
            }

            try Self.setSetting(.reviewRequestedVersion, to: version, in: db)

            return true
        }
    }
}

extension AppDatabase {
    static func entryHistory(in db: Database) throws -> EntryHistory {
        let count = try Entry.fetchCount(db)
        let first = try Entry.order(Column("created_at")).fetchOne(db)
        return EntryHistory(count: count, firstCreatedAt: first?.createdAt)
    }
}
