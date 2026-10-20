import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct HomeModelTests {
    @Test
    func sumsMonthTodayAndYesterday() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        try await setup.save(.expense, amount: 220, daysAgo: 0)
        try await setup.save(.expense, amount: 4500, daysAgo: 1)
        try await setup.save(.income, amount: 250_000, daysAgo: 2)
        try await setup.save(.expense, amount: 3000, daysAgo: 30)
        let model = HomeModel(database: setup.database, today: setup.today)

        await model.load()

        #expect(model.monthExpense == 5700)
        #expect(model.monthIncome == 250_000)
        #expect(model.todayExpense == 1200)
        #expect(model.yesterdayExpense == 4500)
        #expect(model.monthRangeText == "10/1〜10/31")
    }

    @Test
    func sumsUpcomingRecurringExpense() async throws {
        let setup = try await Setup()
        try await setup.saveRecurring(amount: 4800, day: 5)
        try await setup.saveRecurring(amount: 78000, day: 27)
        let model = HomeModel(database: setup.database, today: setup.today)

        await model.load()

        #expect(model.recurringExpense == 82800)
        #expect(model.upcomingRecurringExpense == 78000)
        #expect(model.periodRecurrings.map(\.date.day) == [5, 27])
        #expect(model.periodRecurrings.map(\.status) == [.done, .upcoming])
    }

    @Test
    func marksAndRecordsMissingRecurring() async throws {
        let setup = try await Setup()
        try await setup.saveRecurring(amount: 4800, day: 5)
        try await setup.saveRecurring(amount: 78000, day: 27)
        let model = HomeModel(database: setup.database, today: setup.today)
        await model.load()
        let entry = try #require(model.periodRecurrings.first?.entry)

        try await setup.database.deleteEntry(entry.id)
        await model.load()

        #expect(model.periodRecurrings.map(\.status) == [.missing, .upcoming])
        #expect(model.paidRecurringExpense == 0)
        #expect(model.recurringExpense == 82800)

        let missing = try #require(model.periodRecurrings.first)
        await model.record(missing)
        await model.load()

        #expect(model.periodRecurrings.map(\.status) == [.done, .upcoming])
    }

    @Test
    func leavesUpcomingRecurringOutOfPerDay() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 45000, daysAgo: 0)
        try await setup.saveRecurring(amount: 30000, day: 27)
        let model = HomeModel(database: setup.database, today: setup.today)
        let month = setup.today.yearMonth
        await model.load()

        let task = Task {
            await model.run()
        }

        try await setup.database.setBudget(120_000, for: nil, from: month)

        for _ in 0..<200 where model.budgetUsage == nil {
            try await Task.sleep(for: .milliseconds(10))
        }

        task.cancel()

        #expect(model.budgetUsage?.remaining == 75000)
        #expect(model.budgetUsage?.perDay == 2250)
    }

    @Test
    func showsRemainingBudgetOfPeriod() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 45000, daysAgo: 0)
        let model = HomeModel(database: setup.database, today: setup.today)
        let month = setup.today.yearMonth
        await model.load()
        let before = model.budgetUsage

        let task = Task {
            await model.run()
        }

        try await setup.database.setBudget(120_000, for: nil, from: month)

        for _ in 0..<200 where model.budgetUsage == nil {
            try await Task.sleep(for: .milliseconds(10))
        }

        task.cancel()

        #expect(before == nil)
        #expect(model.budgetUsage?.remaining == 75000)
        #expect(model.budgetUsage?.perDay == 3750)
    }

    @Test
    func listsRecentEntriesNewestFirst() async throws {
        let setup = try await Setup()

        for daysAgo in 0..<7 {
            let amount = 100 + daysAgo
            let memo = "メモ\(daysAgo)"
            try await setup.save(
                .expense,
                amount: amount,
                daysAgo: daysAgo,
                memo: memo
            )
        }

        let model = HomeModel(database: setup.database, today: setup.today)

        await model.load()
        let rows = model.recentRows

        #expect(rows.count == HomeModel.recentLimit)
        #expect(rows.map(\.amount) == [100, 101, 102, 103, 104])
        #expect(rows.first?.title == "食費")
        #expect(rows.first?.detail == "今日・メモ0・財布")
        #expect(rows[1].detail == "昨日・メモ1・財布")
        #expect(rows[2].detail == "10/10・メモ2・財布")
    }
}

extension HomeModelTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
    }
}

extension HomeModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let today = try #require(LocalDate("2026-10-12"))
        self.init(database: database, today: today)
    }

    func saveRecurring(
        amount: Int,
        day: Int
    ) async throws {
        let options = try await database.entryOptions()
        let start = try #require(LocalDate("2026-10-01"))
        let draft = RecurringDraft(
            type: .expense,
            amount: amount,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets.first?.id,
            frequency: .monthly,
            month: 1,
            day: day,
            startDate: start
        )

        _ = try await database.saveRecurring(draft, today: today, at: Date())
    }

    func save(
        _ type: Entry.Kind,
        amount: Int,
        daysAgo: Int,
        memo: String = ""
    ) async throws {
        let options = try await database.entryOptions()
        let categories = type == .income
            ? options.incomeCategories
            : options.expenseCategories
        let offset = TimeInterval(daysAgo)
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000 - offset)

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: today.adding(days: -daysAgo),
            categoryId: categories.first?.id,
            walletId: options.wallets[0].id,
            memo: memo
        )

        try await database.saveEntry(draft, at: createdAt)
    }
}
