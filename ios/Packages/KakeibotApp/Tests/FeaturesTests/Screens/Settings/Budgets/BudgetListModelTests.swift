import Core
import FeatureModels
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
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let food = try #require(model.output.categories.first)
        let emptyTitle = model.output.saveTitle

        model.startEditing(.total)
        model.state.press(.digit(1))
        model.state.press(.digit(2))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        let title = model.output.saveTitle
        await model.save()

        model.startEditing(.category(food))
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        await model.save()
        let budgets = try await setup.database.budgets()

        #expect(model.input.month == YearMonth(year: 2026, month: 11))
        #expect(emptyTitle == "金額を入れてください")
        #expect(title == "11月からこの額にする")
        #expect(model.output.totalAmount == 120_000)
        #expect(model.output.amount(for: food.id) == 30000)
        #expect(model.output.categoriesTotal == 30000)
        #expect(model.state.editing == nil)
        #expect(budgets.allSatisfy { $0.fromMonth == model.input.month })
    }

    @Test
    func clearsBudget() async throws {
        let setup = try await HomeModelTests.Setup()
        let month = setup.today.yearMonth
        try await setup.database.setBudget(50000, for: nil, from: month)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        model.startEditing(.total)
        let current = model.state.calculator.amount
        let cleared = try #require(await model.clear())
        let afterClear = model.output.totalAmount

        await model.restore(cleared)
        let budgets = try await setup.database.budgets()

        #expect(current == 50000)
        #expect(afterClear == nil)
        #expect(cleared.target.title == "月全体の予算")
        #expect(model.state.cleared.current == cleared)
        #expect(model.output.totalAmount == 50000)
        #expect(budgets.count == 1)
    }

    @Test
    func restoresBudgetCarriedFromEarlierMonth() async throws {
        let setup = try await HomeModelTests.Setup()
        let month = setup.today.yearMonth
        let earlier = month.adding(months: -2)
        try await setup.database.setBudget(30000, for: nil, from: earlier)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        model.startEditing(.total)
        let cleared = try #require(await model.clear())
        await model.restore(cleared)
        let budgets = try await setup.database.budgets()

        #expect(model.output.totalAmount == 30000)
        #expect(budgets.map(\.fromMonth) == [earlier])
    }

    @Test
    func savesWithDoneAndShowsSpending() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 9000, daysAgo: 0)
        try await setup.save(.income, amount: 50000, daysAgo: 0)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let food = try #require(model.output.categories.first)
        model.startEditing(.category(food))
        model.state.press(.digit(1))
        model.state.press(.digit(0))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        await model.finishEditing()
        let usage = try #require(model.output.usage(for: food.id))

        model.startEditing(.total)
        await model.finishEditing()

        #expect(model.output.amount(for: food.id) == 10000)
        #expect(usage.spent == 9000)
        #expect(usage.remaining == 1000)
        #expect(usage.isNearLimit)
        #expect(model.output.spent(for: nil) == 9000)
        #expect(model.output.totalAmount == nil)
        #expect(model.state.editing == nil)
    }

    @Test
    func detectsChangedAmountWhileEditing() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.database.setBudget(50000, for: nil, from: setup.today.yearMonth)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let closed = model.output.isChanged

        model.startEditing(.total)
        let opened = model.output.isChanged

        model.state.press(.digit(1))
        let changed = model.output.isChanged

        model.cancelEditing()
        let canceled = model.output.isChanged

        #expect(!closed)
        #expect(!opened)
        #expect(changed)
        #expect(!canceled)
        #expect(model.output.totalAmount == 50000)
    }

    @Test
    func asksBeforeDiscardingChangedAmount() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.database.setBudget(50000, for: nil, from: setup.today.yearMonth)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)
        await model.load()

        model.startEditing(.total)
        model.closeEditing()
        let unchanged = model.state.editing

        model.startEditing(.total)
        model.state.press(.digit(1))
        model.closeEditing()
        let isAsking = model.state.presented.prompt.isShowing(.discard)
        let kept = model.state.editing

        model.cancelEditing()

        #expect(unchanged == nil)
        #expect(isAsking)
        #expect(kept == .total)
        #expect(!model.state.presented.prompt.isShowing(.discard))
        #expect(model.state.editing == nil)
    }

    @Test
    func turnsCarryoverOnFromPeriodMonthAndOff() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let initial = model.output.isCarryoverOn

        await model.setCarryover(true)
        let stored = try await setup.database.setting(.budgetCarryoverFrom)
        let enabled = model.output.isCarryoverOn

        await model.setCarryover(false)
        let cleared = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(!initial)
        #expect(stored == model.input.month)
        #expect(enabled)
        #expect(cleared == nil)
        #expect(!model.output.isCarryoverOn)
    }

    @Test
    func carriesOnlyTotalBudgetRemainingIntoTotalUsage() async throws {
        let setup = try await carryoverSetup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let food = try #require(model.output.categories.first)
        let total = try #require(model.output.usage(for: nil))
        let category = try #require(model.output.usage(for: food.id))

        #expect(model.output.carryover == 70000)
        #expect(total.carryover == 70000)
        #expect(category.carryover == 0)
    }

    @Test
    func resetsCarryoverAndRestoresStart() async throws {
        let setup = try await carryoverSetup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let start = model.input.carryoverFrom
        let previous = try #require(await model.resetCarryover())
        let reset = model.output.carryover
        let resetStart = try await setup.database.setting(.budgetCarryoverFrom)

        await model.restoreCarryover(from: previous)
        let restoredStart = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(previous == start)
        #expect(model.state.resetFrom.current == previous)
        #expect(reset == 0)
        #expect(resetStart == model.input.month)
        #expect(model.output.carryover == 70000)
        #expect(restoredStart == start)
    }

    @Test
    func keepsCarryoverWhenResetIsNotNeeded() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let off = await model.resetCarryover()

        await model.setCarryover(true)
        let zero = await model.resetCarryover()
        let stored = try await setup.database.setting(.budgetCarryoverFrom)

        #expect(off == nil)
        #expect(model.output.carryover == 0)
        #expect(zero == nil)
        #expect(model.state.resetFrom.current == nil)
        #expect(stored == model.input.month)
    }

    @Test
    func suggestsLastMonthAverageAndRecurring() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 48200, daysAgo: 20)
        try await setup.save(.expense, amount: 40000, daysAgo: 50)
        try await setup.save(.expense, amount: 45150, daysAgo: 80)
        try await setup.save(.income, amount: 300_000, daysAgo: 20)
        try await setup.saveRecurring(amount: 82800, day: 25)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let closed = model.output.suggestions

        model.startEditing(.total)
        let total = model.output.suggestions

        let food = try #require(model.output.categories.first)
        model.startEditing(.category(food))
        let category = model.output.suggestions
        let average = try #require(category.last)
        model.state.choose(average)

        #expect(closed.isEmpty)
        #expect(total.map(\.title) == ["先月", "3 か月の平均", "固定費"])
        #expect(total.map(\.amount) == [48200, 44500, 82800])
        #expect(category.map(\.amount) == [48200, 44500])
        #expect(model.state.calculator.amount == 44500)
    }

    @Test
    func averagesOnlyMonthsSinceFirstRecord() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 30000, daysAgo: 20)
        try await setup.save(.expense, amount: 20001, daysAgo: 50)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        model.startEditing(.total)

        #expect(model.output.suggestions.map(\.amount) == [30000, 25100])
    }

    @Test
    func skipsAverageUntilTwoMonthsAreRecorded() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 30000, daysAgo: 20)
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        model.startEditing(.total)

        #expect(model.output.suggestions.map(\.title) == ["先月"])
    }

    @Test
    func suggestsOnlyRecurringWithoutRecords() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        model.startEditing(.total)
        let empty = model.output.suggestions

        try await setup.saveRecurring(amount: 82800, day: 25)
        await model.load()
        model.startEditing(.total)
        let total = model.output.suggestions

        let food = try #require(model.output.categories.first)
        model.startEditing(.category(food))

        #expect(empty.isEmpty)
        #expect(total.map(\.title) == ["固定費"])
        #expect(total.map(\.amount) == [82800])
        #expect(model.output.suggestions.isEmpty)
    }

    @Test
    func tellsWhenBudgetsCannotBeRead() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)
        try await setup.database.failReads(of: "setting")

        await model.load()

        #expect(model.state.errorNotice.message == "予算を読めませんでした")
    }

    @Test
    func keepsNoticeWhenEditingStarts() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = BudgetListModel(parts: .system(setup.database), today: setup.today)
        try await setup.database.failReads(of: "setting")
        await model.load()

        model.startEditing(.total)

        #expect(model.state.errorNotice.message == "予算を読めませんでした")
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
