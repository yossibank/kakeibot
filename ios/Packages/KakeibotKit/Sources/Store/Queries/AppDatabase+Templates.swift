import Core
import GRDB

public extension AppDatabase {
    func templateUpdates(
        includingHidden: Bool = false
    ) -> some AsyncSequence<[EntryTemplate], any Error> {
        ValueObservation
            .tracking { db in
                try Self.templates(in: db, includingHidden: includingHidden)
            }
            .values(in: writer)
    }

    func templates(
        includingHidden: Bool = false
    ) async throws -> [EntryTemplate] {
        try await writer.read { db in
            try Self.templates(in: db, includingHidden: includingHidden)
        }
    }
}

private extension AppDatabase {
    static func templates(
        in db: Database,
        includingHidden: Bool
    ) throws -> [EntryTemplate] {
        let request = includingHidden
            ? EntryTemplate.all()
            : EntryTemplate.filter(Column("archived_at") == nil)

        return try request
            .order(EntryTemplate.sortOrder, Column("created_at"))
            .fetchAll(db)
    }
}
