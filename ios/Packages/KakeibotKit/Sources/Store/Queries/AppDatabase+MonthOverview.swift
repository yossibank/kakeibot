import Core
import GRDB

public extension AppDatabase {
    func monthOverviewUpdates(
        on today: LocalDate
    ) -> some AsyncSequence<MonthOverview, any Error> {
        EntryListJoin.updates(in: self) { db in
            try Self.monthPlan(on: today, in: db)
        } join: { list, plan in
            plan.with(list)
        }
    }

    func monthOverview(on today: LocalDate) async throws -> MonthOverview {
        try await writer.read { db in
            let list = try Self.entryList(in: db)
            let plan = try Self.monthPlan(on: today, in: db)

            return plan.with(list)
        }
    }
}

private extension AppDatabase {
    static func monthPlan(
        on today: LocalDate,
        in db: Database
    ) throws -> MonthOverview {
        let budgets = try budgets(in: db)
        let recurrings = try recurrings(in: db)
        let monthStartDay = try setting(.monthStartDay, in: db)

        return MonthOverview(
            list: nil,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            today: today
        )
    }
}

private extension MonthOverview {
    func with(_ list: EntryList) -> MonthOverview {
        MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            today: today
        )
    }
}
