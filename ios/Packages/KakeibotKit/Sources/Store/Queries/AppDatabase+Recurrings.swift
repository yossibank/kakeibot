import Core
import GRDB

public extension AppDatabase {
    func recurringUpdates(
        includingHidden: Bool = false
    ) -> some AsyncSequence<[Recurring], any Error> {
        ValueObservation
            .tracking { db in
                try Self.recurrings(in: db, includingHidden: includingHidden)
            }
            .values(in: writer)
    }

    func recurrings(
        includingHidden: Bool = false
    ) async throws -> [Recurring] {
        try await writer.read { db in
            try Self.recurrings(in: db, includingHidden: includingHidden)
        }
    }
}

extension AppDatabase {
    static func recurrings(
        in db: Database,
        includingHidden: Bool = false
    ) throws -> [Recurring] {
        let request = includingHidden
            ? Recurring.all()
            : Recurring.filter(Column("archived_at") == nil)

        return try request
            .order(Recurring.sortOrder, Column("created_at"))
            .fetchAll(db)
    }
}
