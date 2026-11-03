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
        try await setup.database.setSetting(.monthStartDay, to: payday)
        let model = BudgetListModel(database: setup.database, today: setup.today)

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
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        model.startEditing(.total)
        let current = model.calculator.amount
        let cleared = try #require(await model.clear())
        let afterClear = model.totalAmount

        await model.restore(cleared)
        let budgets = try await setup.database.budgets()

        #expect(current == 50000)
        #expect(afterClear == nil)
        #expect(cleared.target.title == "月全体の予算")
        #expect(model.totalAmount == 50000)
        #expect(budgets.count == 1)
    }

    @Test
    func restoresBudgetCarriedFromEarlierMonth() async throws {
        let setup = try await HomeModelTests.Setup()
        let month = setup.today.yearMonth
        let earlier = month.adding(months: -2)
        try await setup.database.setBudget(30000, for: nil, from: earlier)
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        model.startEditing(.total)
        let cleared = try #require(await model.clear())
        await model.restore(cleared)
        let budgets = try await setup.database.budgets()

        #expect(model.totalAmount == 30000)
        #expect(budgets.map(\.fromMonth) == [earlier])
    }

    @Test
    func savesWithDoneAndShowsSpending() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 9000, daysAgo: 0)
        try await setup.save(.income, amount: 50000, daysAgo: 0)
        let model = BudgetListModel(database: setup.database, today: setup.today)

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

    @Test
    func detectsChangedAmountWhileEditing() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.database.setBudget(50000, for: nil, from: setup.today.yearMonth)
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        let closed = model.isChanged

        model.startEditing(.total)
        let opened = model.isChanged

        model.press(.digit(1))
        let changed = model.isChanged

        model.cancelEditing()
        let canceled = model.isChanged

        #expect(!closed)
        #expect(!opened)
        #expect(changed)
        #expect(!canceled)
        #expect(model.totalAmount == 50000)
    }

    @Test
    func turnsCarryoverOnFromPeriodMonthAndOff() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        let initial = model.isCarryoverOn

        await model.setCarryover(true)
        let stored = try await setup.database.setting(.budgetCarryoverFrom)
        let enabled = model.isCarryoverOn

        await model.setCarryover(false)
        let cleared = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(!initial)
        #expect(stored == model.month)
        #expect(enabled)
        #expect(cleared == nil)
        #expect(!model.isCarryoverOn)
    }

    @Test
    func carriesOnlyTotalBudgetRemainingIntoTotalUsage() async throws {
        let setup = try await carryoverSetup()
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        let food = try #require(model.categories.first)
        let total = try #require(model.usage(for: nil))
        let category = try #require(model.usage(for: food.id))

        #expect(model.carryover == 70000)
        #expect(total.carryover == 70000)
        #expect(category.carryover == 0)
    }

    @Test
    func resetsCarryoverAndRestoresStart() async throws {
        let setup = try await carryoverSetup()
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        let start = model.carryoverFrom
        let previous = try #require(await model.resetCarryover())
        let reset = model.carryover
        let resetStart = try await setup.database.setting(.budgetCarryoverFrom)

        await model.restoreCarryover(from: previous)
        let restoredStart = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(previous == start)
        #expect(reset == 0)
        #expect(resetStart == model.month)
        #expect(model.carryover == 70000)
        #expect(restoredStart == start)
    }

    @Test
    func keepsCarryoverWhenResetIsNotNeeded() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(database: setup.database, today: setup.today)

        await model.load()
        let off = await model.resetCarryover()

        await model.setCarryover(true)
        let zero = await model.resetCarryover()
        let stored = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(off == nil)
        #expect(model.carryover == 0)
        #expect(zero == nil)
        #expect(stored == model.month)
    }
}

private extension BudgetListModelTests {
    func carryoverSetup() async throws -> HomeModelTests.Setup {
        let setup = try await HomeModelTests.Setup()
        let options = try await setup.database.entryOptions()
        let food = try #require(options.expenseCategories.first)
        let earlier = setup.today.yearMonth.adding(months: -3)
        let start = setup.today.yearMonth.adding(months: -2)

        try await setup.database.setBudget(50000, for: nil, from: earlier)
        try await setup.database.setBudget(99999, for: food.id, from: earlier)
        try await setup.save(.expense, amount: 10000, daysAgo: 50)
        try await setup.save(.expense, amount: 20000, daysAgo: 20)
        try await setup.database.setSetting(.budgetCarryoverFrom, to: start)

        return setup
    }
}
