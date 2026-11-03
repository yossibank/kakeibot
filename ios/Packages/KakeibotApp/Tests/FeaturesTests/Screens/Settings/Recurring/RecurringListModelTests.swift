import Core
import Features
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
        let model = RecurringListModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            !model.rows.isEmpty
        }

        task.cancel()
        let row = try #require(model.rows.first)

        #expect(row.title == "家賃")
        #expect(row.schedule == "毎月 27 日")
        #expect(row.place == "財布")
        #expect(row.next?.description == "2026-10-27")
        #expect(model.monthTotal.expense == 78000)
        #expect(model.monthTotal.income == 0)
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
        let model = RecurringListModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.observe()
        }

        await ObservationWait.until {
            !model.rows.isEmpty
        }

        await model.hide(saved.id)

        await ObservationWait.until {
            !model.hiddenRows.isEmpty
        }

        let shownWhileHidden = model.rows.count
        let totalWhileHidden = model.monthTotal.expense

        await model.show(saved.id)

        await ObservationWait.until {
            !model.rows.isEmpty
        }

        task.cancel()

        #expect(shownWhileHidden == 0)
        #expect(totalWhileHidden == 0)
        #expect(model.hiddenRows.isEmpty)
        #expect(model.rows.first?.title == "家賃")
    }
}
