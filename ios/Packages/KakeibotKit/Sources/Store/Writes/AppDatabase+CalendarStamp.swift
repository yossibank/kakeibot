import Core
import Foundation
import GRDB

public extension AppDatabase {
    @discardableResult
    func stamp(
        _ iconId: Icon.ID,
        on date: LocalDate,
        at now: Date
    ) async throws -> CalendarStamp {
        try await writer.write { db in
            try CalendarStamp
                .filter(Column("date") == date)
                .deleteAll(db)

            let stamp = CalendarStamp(
                date: date,
                iconId: iconId,
                createdAt: now
            )

            try stamp.insert(db)
            return stamp
        }
    }

    func removeStamp(on date: LocalDate) async throws {
        try await writer.write { db in
            _ = try CalendarStamp
                .filter(Column("date") == date)
                .deleteAll(db)
        }
    }
}
