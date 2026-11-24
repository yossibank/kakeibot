import Core
@testable import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct RecurringListModelTests {
    @Test
    func listsWithScheduleAndNextDate() async throws {
        let setup = try await RecordsModelTests.Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-10-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        let model = RecurringListModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            !model.output.rows.isEmpty
        }

        task.cancel()
        let row = try #require(model.output.rows.first)

        #expect(row.title == "家賃")
        #expect(row.schedule == "毎月 27 日")
        #expect(row.place == "財布")
        #expect(row.next?.description == "2026-10-27")
        #expect(model.output.monthTotal == 78000)

        model.state.type = .income

        #expect(model.output.rows.isEmpty)
        #expect(model.output.monthTotal == 0)
    }

    @Test
    func totalsMonthFromMonthStartDay() async throws {
        let setup = try await RecordsModelTests.Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-10-01"))
        let payday = try #require(MonthStartDay(25))
        try await setup.database.setSetting(.monthStartDay, to: payday)

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        let model = RecurringListModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            !model.output.rows.isEmpty && model.input.monthStartDay == payday
        }

        task.cancel()

        #expect(model.output.monthTotal == 0)
    }

    @Test
    func hidesAndShowsRecurring() async throws {
        let setup = try await RecordsModelTests.Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-10-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        let saved = try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        let model = RecurringListModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            !model.output.rows.isEmpty
        }

        await model.hide(saved.id)

        await ObservationWait.until {
            !model.output.hiddenRows.isEmpty
        }

        let shownWhileHidden = model.output.rows.count
        let totalWhileHidden = model.output.monthTotal

        await model.show(saved.id)

        await ObservationWait.until {
            !model.output.rows.isEmpty
        }

        task.cancel()

        #expect(shownWhileHidden == 0)
        #expect(totalWhileHidden == 0)
        #expect(model.output.hiddenRows.isEmpty)
        #expect(model.output.rows.first?.title == "家賃")
    }
}
