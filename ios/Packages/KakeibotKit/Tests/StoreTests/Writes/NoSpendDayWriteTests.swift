import Core
import Foundation
import Store
import Testing

struct NoSpendDayWriteTests {
    @Test
    func marksAndUnmarksDay() async throws {
        let setup = try await Setup()
        var updates = setup.database.noSpendDayUpdates().makeAsyncIterator()

        let initial = try await updates.next()
        try await setup.database.markNoSpendDay(setup.date, at: setup.now)
        let marked = try await updates.next()
        try await setup.database.unmarkNoSpendDay(setup.date)
        let unmarked = try await updates.next()

        #expect(initial == [])
        #expect(marked == [setup.date])
        #expect(unmarked == [])
    }

    @Test
    func rejectsDayWithExpense() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: setup.date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: ""
        )

        try await setup.database.saveEntry(draft, at: setup.now)

        await #expect(throws: AppDatabase.NoSpendDayError.hasExpense) {
            try await setup.database.markNoSpendDay(setup.date, at: setup.now)
        }
    }

    @Test
    func marksDayWithOnlyIncome() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()

        let draft = EntryDraft(
            type: .income,
            amount: 3000,
            date: setup.date,
            categoryId: options.incomeCategories[0].id,
            walletId: options.wallets[0].id,
            memo: ""
        )

        try await setup.database.saveEntry(draft, at: setup.now)
        try await setup.database.markNoSpendDay(setup.date, at: setup.now)
        let snapshot = try setup.database.snapshot()

        #expect(snapshot.noSpendDays.map(\.date) == [setup.date])
    }
}

extension NoSpendDayWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let date: LocalDate
    }
}

extension NoSpendDayWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let date = try #require(LocalDate("2026-10-03"))

        self.init(
            database: database,
            now: now,
            date: date
        )
    }
}
