@testable import AppWidget
import Core
import Foundation
import Store
import Testing

struct BudgetWidgetSummaryTests {
    @Test
    func countsWeekFromChosenWeekStart() async throws {
        let setup = try await Setup()
        try await setup.saveEntry(amount: 500, on: setup.monday.adding(days: -1))
        try await setup.saveEntry(amount: 300, on: setup.monday)
        let overview = try await setup.database.widgetOverview(on: setup.monday)

        let fromSunday = BudgetWidgetSummary(overview, weekStart: .sunday)
        let fromMonday = BudgetWidgetSummary(overview, weekStart: .monday)

        #expect(fromSunday.weekExpense == 800)
        #expect(fromMonday.weekExpense == 300)
        #expect(fromMonday.todayExpense == 300)
        #expect(fromMonday.yesterdayExpense == 500)
    }

    @Test
    func namesNextRecurringAfterCategoryWithoutMemo() async throws {
        let setup = try await Setup()
        try await setup.saveRecurring(memo: "", day: 20)
        let overview = try await setup.database.widgetOverview(on: setup.monday)

        let summary = BudgetWidgetSummary(overview, weekStart: .sunday)

        #expect(summary.nextRecurring?.title == setup.categoryName)
        #expect(summary.nextRecurring?.amount == 80000)
        #expect(summary.nextRecurring?.date == LocalDate("2026-10-20"))
    }

    @Test
    func namesNextRecurringAfterMemo() async throws {
        let setup = try await Setup()
        try await setup.saveRecurring(memo: "家賃", day: 20)
        let overview = try await setup.database.widgetOverview(on: setup.monday)

        let summary = BudgetWidgetSummary(overview, weekStart: .sunday)

        #expect(summary.nextRecurring?.title == "家賃")
    }

    @Test
    func leavesUsageEmptyWithoutBudget() async throws {
        let setup = try await Setup()
        try await setup.saveEntry(amount: 300, on: setup.monday)
        let before = try await setup.database.widgetOverview(on: setup.monday)
        try await setup.database.setBudget(90000, for: nil, from: setup.monday.yearMonth)
        let after = try await setup.database.widgetOverview(on: setup.monday)

        let withoutBudget = BudgetWidgetSummary(before, weekStart: .sunday)
        let withBudget = BudgetWidgetSummary(after, weekStart: .sunday)

        #expect(withoutBudget.usage == nil)
        #expect(withoutBudget.monthExpense == 300)
        #expect(withBudget.usage?.budget == 90000)
        #expect(withBudget.nextRecurring == nil)
    }
}

extension BudgetWidgetSummaryTests {
    struct Setup {
        let database: AppDatabase
        let monday: LocalDate
        let options: EntryOptions
    }
}

extension BudgetWidgetSummaryTests.Setup {
    var categoryName: String? {
        options.expenseCategories.first?.name
    }

    init() async throws {
        let database = try AppDatabase.inMemory()
        let monday = try #require(LocalDate("2026-10-12"))

        try database.insertDefaultsIfEmpty(at: Date())

        let options = try await database.entryOptions()

        self.init(
            database: database,
            monday: monday,
            options: options
        )
    }

    func saveEntry(
        amount: Int,
        on date: LocalDate
    ) async throws {
        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: date,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets[0].id
        )

        _ = try await database.saveEntry(draft, at: Date())
    }

    func saveRecurring(
        memo: String,
        day: Int
    ) async throws {
        let draft = RecurringDraft(
            type: .expense,
            amount: 80000,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets.first?.id,
            memo: memo,
            frequency: .monthly,
            month: 1,
            day: day,
            startDate: monday
        )

        _ = try await database.saveRecurring(draft, today: monday, at: Date())
    }
}
