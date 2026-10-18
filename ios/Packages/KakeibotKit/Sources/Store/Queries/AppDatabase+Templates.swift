import Core
import GRDB

public extension AppDatabase {
    func templateUpdates() -> some AsyncSequence<[EntryTemplate], any Error> {
        ValueObservation
            .tracking(Self.templates)
            .values(in: writer)
    }

    func templates() async throws -> [EntryTemplate] {
        try await writer.read(Self.templates)
    }
}

private extension AppDatabase {
    static func templates(in db: Database) throws -> [EntryTemplate] {
        try EntryTemplate
            .order(EntryTemplate.sortOrder, Column("created_at"))
            .fetchAll(db)
    }
}
