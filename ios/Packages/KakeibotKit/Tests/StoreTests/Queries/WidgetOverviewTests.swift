import Core
import Foundation
import Store
import Testing

struct WidgetOverviewTests {
    @Test
    func matchesFullOverviewForTodayAndTomorrow() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let bill = try await database.insertCardBill(at: now)
        let card = try #require(bill.toWalletId)
        let today = try #require(LocalDate("2026-10-17"))
        let month = try #require(YearMonth("2026-10"))
        let longAgo = try #require(LocalDate("2025-01-05"))
        let wallets = [options.wallets[0].id, card]

        for index in 0..<120 {
            let draft = EntryDraft(
                type: .expense,
                amount: 100 + index,
                date: today.adding(days: -index * 6),
                categoryId: options.expenseCategories[0].id,
                walletId: wallets[index % wallets.count]
            )

            try await database.saveEntry(draft, at: now)
        }

        let deferred = EntryDraft(
            type: .expense,
            amount: 7000,
            date: longAgo,
            categoryId: options.expenseCategories[0].id,
            walletId: card,
            billMonth: month
        )

        let old = EntryDraft(
            type: .expense,
            amount: 300,
            date: longAgo,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        try await database.saveEntry(deferred, at: now)
        let recorded = try await database.saveEntry(old, at: now)
        try await database.setBudget(50000, for: nil, from: month)
        let full = try await database.monthOverview(on: today)
        let widget = try await database.widgetOverview(on: today)
        let including = try await database.widgetOverview(on: today, including: recorded.id)

        for day in [today, today.adding(days: 1), today.adding(days: 15)] {
            let expected = Summary(full.moved(to: day))
            let actual = Summary(widget.moved(to: day))

            #expect(actual == expected)
        }

        #expect(widget.list?.days.flatMap(\.entries).contains(recorded) == false)
        #expect(including.list?.days.flatMap(\.entries).contains(recorded) == true)
        #expect(widget.list?.days.count ?? 0 < full.list?.days.count ?? 0)
    }
}

extension WidgetOverviewTests {
    struct Summary: Equatable {
        let monthExpense: Int
        let todayExpense: Int
        let yesterdayExpense: Int
        let weekExpense: Int
        let budgetUsage: BudgetUsage?
        let periodRecurrings: [PeriodRecurring]
        let recentDays: [EntryDay]
    }
}

extension WidgetOverviewTests.Summary {
    init(_ overview: MonthOverview) {
        let today = overview.today
        let week = today.week(startingOn: .sunday)
        let recentStart = today.adding(days: -TemplateOrder.frequentDays)
        let days = overview.list?.days ?? []

        self.init(
            monthExpense: overview.monthExpense,
            todayExpense: overview.todayExpense,
            yesterdayExpense: overview.yesterdayExpense,
            weekExpense: overview.expense(in: week),
            budgetUsage: overview.budgetUsage,
            periodRecurrings: overview.periodRecurrings,
            recentDays: days.filter { $0.date >= recentStart }
        )
    }
}
