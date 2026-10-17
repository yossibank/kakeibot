import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct BudgetListModelTests {
    @Test
    func setsTotalAndCategoryBudgetsFromPeriodMonth() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(10))
        try await setup.database.setMonthStartDay(payday)

        let model = BudgetListModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let food = try #require(model.categories.first)
        let emptyTitle = model.saveTitle

        model.startEditing(.total)
        model.press(.digit(1))
        model.press(.digit(2))
        model.press(.doubleZero)
        model.press(.doubleZero)
        let title = model.saveTitle
        await model.save()

        model.startEditing(.category(food))
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.doubleZero)
        await model.save()
        let budgets = try await setup.database.budgets()

        #expect(model.month == YearMonth(year: 2026, month: 11))
        #expect(emptyTitle == "金額を入れてください")
        #expect(title == "11月からこの額にする")
        #expect(model.totalAmount == 120_000)
        #expect(model.amount(for: food.id) == 30000)
        #expect(model.categoriesTotal == 30000)
        #expect(model.editing == nil)
        #expect(budgets.allSatisfy { $0.fromMonth == model.month })
    }

    @Test
    func clearsBudget() async throws {
        let setup = try await HomeModelTests.Setup()
        let month = setup.today.yearMonth
        try await setup.database.setBudget(50000, for: nil, from: month)

        let model = BudgetListModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        model.startEditing(.total)
        let current = model.calculator.amount
        await model.clear()

        #expect(current == 50000)
        #expect(model.totalAmount == nil)
    }

    @Test
    func savesWithDoneAndShowsSpending() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 9000, daysAgo: 0)
        try await setup.save(.income, amount: 50000, daysAgo: 0)

        let model = BudgetListModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let food = try #require(model.categories.first)
        model.startEditing(.category(food))
        model.press(.digit(1))
        model.press(.digit(0))
        model.press(.doubleZero)
        model.press(.digit(0))
        await model.finishEditing()
        let usage = try #require(model.usage(for: food.id))

        model.startEditing(.total)
        await model.finishEditing()

        #expect(model.amount(for: food.id) == 10000)
        #expect(usage.spent == 9000)
        #expect(usage.remaining == 1000)
        #expect(usage.isNearLimit)
        #expect(model.spent(for: nil) == 9000)
        #expect(model.totalAmount == nil)
        #expect(model.editing == nil)
    }
}
