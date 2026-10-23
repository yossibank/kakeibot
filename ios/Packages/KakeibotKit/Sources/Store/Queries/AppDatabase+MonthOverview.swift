import Core
import GRDB

public extension AppDatabase {
    func monthOverviewUpdates(
        on today: LocalDate
    ) -> some AsyncSequence<MonthOverview, any Error> {
        ValueObservation
            .tracking { db in
                try Self.monthOverview(on: today, in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func monthOverview(on today: LocalDate) async throws -> MonthOverview {
        try await writer.read { db in
            try Self.monthOverview(on: today, in: db)
        }
    }
}

private extension AppDatabase {
    static func monthOverview(
        on today: LocalDate,
        in db: Database
    ) throws -> MonthOverview {
        try MonthOverview(
            list: entryList(in: db),
            budgets: budgets(in: db),
            recurrings: recurrings(in: db),
            monthStartDay: setting(.monthStartDay, in: db),
            today: today
        )
    }
}
