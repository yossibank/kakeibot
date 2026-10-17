import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum NoSpendDayError: Error, Equatable {
        case hasExpense
    }

    func markNoSpendDay(
        _ date: LocalDate,
        at now: Date
    ) async throws {
        try await markNoSpendDays([date], at: now)
    }

    func markNoSpendDays(
        _ dates: [LocalDate],
        at now: Date
    ) async throws {
        try await writer.write { db in
            for date in dates {
                let expenses = try Entry
                    .filter(Column("date") == date)
                    .filter(Column("type") == Entry.Kind.expense)
                    .fetchCount(db)

                guard expenses == 0 else {
                    throw NoSpendDayError.hasExpense
                }

                try NoSpendDay(date: date, createdAt: now).save(db)
            }
        }
    }

    func unmarkNoSpendDay(_ date: LocalDate) async throws {
        try await writer.write { db in
            _ = try NoSpendDay.deleteOne(db, key: date)
        }
    }
}
