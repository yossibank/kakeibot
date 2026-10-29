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
        let list = try entryList(in: db)
        let budgets = try budgets(in: db)
        let recurrings = try recurrings(in: db)
        let monthStartDay = try setting(.monthStartDay, in: db)

        return MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            today: today
        )
    }
}
