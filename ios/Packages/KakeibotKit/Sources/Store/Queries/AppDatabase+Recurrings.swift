import Core
import GRDB

public extension AppDatabase {
    func recurringUpdates() -> some AsyncSequence<[Recurring], any Error> {
        ValueObservation
            .tracking(Self.recurrings)
            .values(in: writer)
    }

    func recurrings() async throws -> [Recurring] {
        try await writer.read(Self.recurrings)
    }
}

extension AppDatabase {
    static func recurrings(in db: Database) throws -> [Recurring] {
        try Recurring
            .order(Column("day"), Column("created_at"))
            .fetchAll(db)
    }
}
