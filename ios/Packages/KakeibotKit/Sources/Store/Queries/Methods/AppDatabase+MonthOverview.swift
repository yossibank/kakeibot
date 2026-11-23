import Core
import GRDB

public extension AppDatabase {
    func monthOverviewUpdates(on today: LocalDate) -> some AsyncSequence<MonthOverview, any Error> {
        EntryListJoin.updates(in: self) { db in
            try Self.monthPlan(on: today, in: db)
        } join: { list, plan in
            plan.overview(with: list)
        }
    }

    func monthOverview(on today: LocalDate) async throws -> MonthOverview {
        try await writer.read { db in
            let list = try Self.entryList(in: db, includesItems: false)
            let plan = try Self.monthPlan(on: today, in: db)

            return plan.overview(with: list)
        }
    }

    func widgetOverview(
        on today: LocalDate,
        including entryId: Entry.ID? = nil
    ) async throws -> MonthOverview {
        try await writer.read { db in
            let plan = try Self.monthPlan(on: today, in: db)
            let start = plan.widgetStart

            let request = Entry.filter(
                Column("date") >= start
                    || Column("recurring_date") >= start
                    || Column("bill_month") >= start.yearMonth
                    || Column("id") == entryId
            )

            let list = try Self.entryList(of: request, in: db)

            return plan.overview(with: list)
        }
    }
}

private extension AppDatabase {
    static func monthPlan(
        on today: LocalDate,
        in db: Database
    ) throws -> MonthPlan {
        let budgets = try budgets(in: db)
        let recurrings = try recurrings(in: db)
        let monthStartDay = try setting(.monthStartDay, in: db)
        let carryoverFrom = try setting(.budgetCarryoverFrom, in: db)

        return MonthPlan(
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            carryoverFrom: carryoverFrom,
            today: today
        )
    }
}
