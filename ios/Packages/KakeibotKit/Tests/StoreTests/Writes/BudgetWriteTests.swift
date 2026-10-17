import Core
import Foundation
import Store
import Testing

struct BudgetWriteTests {
    @Test
    func keepsEarlierMonthsWhenChanged() async throws {
        let database = try AppDatabase.inMemory()
        let january = try #require(YearMonth(year: 2026, month: 1))
        let april = try #require(YearMonth(year: 2026, month: 4))
        let march = try #require(YearMonth(year: 2026, month: 3))

        try await database.setBudget(100_000, for: nil, from: january)
        try await database.setBudget(120_000, for: nil, from: april)
        let budgets = try await database.budgets()

        #expect(budgets.count == 2)
        #expect(budgets.amount(for: nil, in: march) == 100_000)
        #expect(budgets.amount(for: nil, in: april) == 120_000)
    }

    @Test
    func updatesSameMonthAndDropsRedundantRow() async throws {
        let database = try AppDatabase.inMemory()
        let january = try #require(YearMonth(year: 2026, month: 1))
        let april = try #require(YearMonth(year: 2026, month: 4))

        try await database.setBudget(100_000, for: nil, from: january)
        try await database.setBudget(120_000, for: nil, from: april)
        try await database.setBudget(130_000, for: nil, from: april)
        let updated = try await database.budgets()
        try await database.setBudget(100_000, for: nil, from: april)
        let restored = try await database.budgets()

        #expect(updated.count == 2)
        #expect(updated.amount(for: nil, in: april) == 130_000)
        #expect(restored.count == 1)
        #expect(restored.amount(for: nil, in: april) == 100_000)
    }

    @Test
    func stopsBudgetFromMonthAndSkipsNoChange() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let category = options.expenseCategories[0].id
        let january = try #require(YearMonth(year: 2026, month: 1))
        let july = try #require(YearMonth(year: 2026, month: 7))

        try await database.setBudget(nil, for: nil, from: january)
        let none = try await database.budgets()

        try await database.setBudget(30000, for: category, from: january)
        try await database.setBudget(nil, for: category, from: july)
        let stopped = try await database.budgets()

        #expect(none.isEmpty)
        #expect(stopped.amount(for: category, in: january) == 30000)
        #expect(stopped.amount(for: category, in: july) == nil)
        #expect(stopped.amount(for: nil, in: july) == nil)
    }

    @Test
    func rejectsZero() async throws {
        let database = try AppDatabase.inMemory()
        let january = try #require(YearMonth(year: 2026, month: 1))

        await #expect(throws: AppDatabase.BudgetWriteError.amountNotPositive) {
            try await database.setBudget(0, for: nil, from: january)
        }
    }
}
