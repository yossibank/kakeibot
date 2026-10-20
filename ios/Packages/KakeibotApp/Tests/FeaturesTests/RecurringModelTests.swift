import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct RecurringModelTests {
    @Test
    func savesRecurringAndGeneratesEntries() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        model.press(.digit(7))
        model.press(.digit(8))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.memo = "家賃"
        model.day = 27
        model.startDate = start
        let saved = await model.save()
        let snapshot = try setup.database.snapshot()

        #expect(saved)
        #expect(snapshot.recurrings.count == 1)
        #expect(snapshot.entries.map(\.date.description) == ["2026-09-27"])
        #expect(snapshot.entries.first?.amount == 78000)
    }

    @Test
    func suggestsHolidayShiftFromCategory() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        model.select(.income)
        let salary = model.holidayShift

        model.select(.transfer)
        let transfer = model.holidayShift

        model.choose(.none)
        model.select(.income)
        let chosen = model.holidayShift

        #expect(salary == .previous)
        #expect(transfer == .next)
        #expect(chosen == .none)
    }

    @Test
    func savesTransferBetweenWallets() async throws {
        let setup = try await RecordsModelTests.Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        model.select(.transfer)
        model.press(.digit(3))
        model.press(.digit(0))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.day = 26
        model.startDate = start
        let saved = await model.save()
        let entry = try #require(setup.database.snapshot().entries.first)

        #expect(saved)
        #expect(model.walletTitle == "振替元")
        #expect(entry.type == .transfer)
        #expect(entry.categoryId == nil)
        #expect(entry.toWalletId != nil)
        #expect(entry.toWalletId != entry.walletId)
    }

    @Test
    func refusesSameWalletTransfer() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        model.select(.transfer)
        model.press(.digit(5))
        model.toWalletId = model.walletId
        let saved = await model.save()

        #expect(!saved)
        #expect(model.errorNotice.message == "振替元と振替先を別にしてください")
    }

    @Test
    func refusesEmptyAmount() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = RecurringEditModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let saved = await model.save()

        #expect(!saved)
        #expect(model.errorNotice.message == "金額を入れてください")
    }

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

        try await setup.database.saveRecurring(
            draft,
            today: setup.today,
            at: Date()
        )

        let model = RecurringListModel(
            database: setup.database,
            today: setup.today
        )

        let task = Task {
            await model.observe()
        }

        for _ in 0..<200 where model.rows.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        task.cancel()
        let row = try #require(model.rows.first)

        #expect(row.title == "家賃")
        #expect(row.detail == "毎月 27 日・財布")
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

        let saved = try await setup.database.saveRecurring(
            draft,
            today: setup.today,
            at: Date()
        )

        let model = RecurringListModel(
            database: setup.database,
            today: setup.today
        )

        let task = Task {
            await model.observe()
        }

        for _ in 0..<200 where model.rows.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        await model.hide(saved.id)

        for _ in 0..<200 where model.hiddenRows.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let shownWhileHidden = model.rows.count
        let totalWhileHidden = model.monthTotal.expense

        await model.show(saved.id)

        for _ in 0..<200 where model.rows.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        task.cancel()

        #expect(shownWhileHidden == 0)
        #expect(totalWhileHidden == 0)
        #expect(model.hiddenRows.isEmpty)
        #expect(model.rows.first?.title == "家賃")
    }
}
