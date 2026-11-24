import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func showsBudgetRemainingAfterEnteredAmount() async throws {
        let setup = try await Setup()
        let model = try await Self.budgetModel(setup, budget: 10000)

        let empty = model.output.budgetText
        model.state.press(.digit(3))
        model.state.press(.doubleZero)

        #expect(empty == "今月あといくら ¥9,500")
        #expect(model.output.budgetText == "今月あと ¥9,500 → ¥9,200")
        #expect(model.output.budgetUsageAfterSave?.progress == 0.08)
    }

    @Test
    func showsBudgetOverAfterEnteredAmount() async throws {
        let setup = try await Setup()
        let model = try await Self.budgetModel(setup, budget: 1000)

        model.state.press(.digit(8))
        model.state.press(.doubleZero)

        #expect(model.output.budgetText == "今月あと ¥500 → オーバー ¥300")
        #expect(model.output.budgetUsageAfterSave?.isOver == true)
        #expect(model.output.budgetUsageAfterSave?.progress == 1)
    }

    @Test
    func replacesEditedAmountInBudgetRemaining() async throws {
        let setup = try await Setup()
        try await Self.saveBudgetAndEntry(setup, budget: 10000)
        let entry = try #require(try setup.database.snapshot().entries.first)
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: entry.date
        )

        await model.load()
        model.state.press(.delete)
        model.state.press(.delete)
        model.state.press(.delete)
        model.state.press(.digit(7))
        model.state.press(.doubleZero)

        #expect(model.output.budgetText == "今月あと ¥9,500 → ¥9,300")
        #expect(model.output.budgetUsageAfterSave?.spent == 700)
    }

    @Test
    func showsBudgetBackWithinAfterLoweringEditedAmount() async throws {
        let setup = try await Setup()
        try await Self.saveBudgetAndEntry(setup, budget: 400)
        let entry = try #require(try setup.database.snapshot().entries.first)
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: entry.date
        )

        await model.load()
        model.state.press(.delete)
        model.state.press(.delete)
        model.state.press(.delete)
        model.state.press(.digit(3))
        model.state.press(.doubleZero)

        #expect(model.output.budgetText == "予算オーバー ¥100 → あと ¥100")
        #expect(model.output.budgetUsageAfterSave?.isOver == false)
    }
}

private extension EntryModelTests {
    static func budgetModel(
        _ setup: Setup,
        budget: Int
    ) async throws -> EntryModel {
        try await saveBudgetAndEntry(setup, budget: budget)

        let today = LocalDate(Date(), in: .current)
        let model = EntryModel(database: setup.database, clock: .system, date: today)

        await model.load()

        return model
    }

    static func saveBudgetAndEntry(
        _ setup: Setup,
        budget: Int
    ) async throws {
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first?.id)
        let category = try #require(options.expenseCategories.first?.id)
        let month = LocalDate(Date(), in: .current).yearMonth

        try await setup.database.setBudget(budget, for: nil, from: month)

        try await setup.saveEntry(category: category, wallet: wallet, at: 1)
    }
}
