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
    func listsRecentEntriesNewestFirst() async throws {
        let setup = try await Setup()

        for daysAgo in 0..<7 {
            let amount = 100 + daysAgo
            let memo = "メモ\(daysAgo)"
            try await setup.save(.expense, amount: amount, daysAgo: daysAgo, memo: memo)
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

    func save(
        _ type: Entry.Kind,
        amount: Int,
        daysAgo: Int,
        memo: String = ""
    ) async throws {
        let options = try await database.entryOptions()
        let categories = type == .income ? options.incomeCategories : options.expenseCategories
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000 - TimeInterval(daysAgo))

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
