import Core
import Foundation
import Store
import Testing

struct BudgetWriteTests {
    @Test
    func keepsEarlierMonthsWhenChanged() async throws {
        let database = try AppDatabase.inMemory()

        let january = try #require(
            YearMonth(
                year: 2026,
                month: 1
            )
        )

        let april = try #require(
            YearMonth(
                year: 2026,
                month: 4
            )
        )

        let march = try #require(
            YearMonth(
                year: 2026,
                month: 3
            )
        )

        try await database.setBudget(100_000, for: nil, from: january)
        try await database.setBudget(120_000, for: nil, from: april)
        let budgets = try await database.budgets()
        let marchAmount = budgets.amount(for: nil, in: march)
        let aprilAmount = budgets.amount(for: nil, in: april)

        #expect(budgets.count == 2)
        #expect(marchAmount == 100_000)
        #expect(aprilAmount == 120_000)
    }

    @Test
    func updatesSameMonthAndDropsRedundantRow() async throws {
        let database = try AppDatabase.inMemory()

        let january = try #require(
            YearMonth(
                year: 2026,
                month: 1
            )
        )

        let april = try #require(
            YearMonth(
                year: 2026,
                month: 4
            )
        )

        try await database.setBudget(100_000, for: nil, from: january)
        try await database.setBudget(120_000, for: nil, from: april)
        try await database.setBudget(130_000, for: nil, from: april)
        let updated = try await database.budgets()
        try await database.setBudget(100_000, for: nil, from: april)
        let restored = try await database.budgets()
        let updatedAmount = updated.amount(for: nil, in: april)
        let restoredAmount = restored.amount(for: nil, in: april)

        #expect(updated.count == 2)
        #expect(updatedAmount == 130_000)
        #expect(restored.count == 1)
        #expect(restoredAmount == 100_000)
    }

    @Test
    func stopsBudgetFromMonthAndSkipsNoChange() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let category = options.expenseCategories[0].id

        let january = try #require(
            YearMonth(
                year: 2026,
                month: 1
            )
        )

        let july = try #require(
            YearMonth(
                year: 2026,
                month: 7
            )
        )

        try await database.setBudget(nil, for: nil, from: january)
        let none = try await database.budgets()
        try await database.setBudget(30000, for: category, from: january)
        try await database.setBudget(nil, for: category, from: july)
        let stopped = try await database.budgets()
        let januaryAmount = stopped.amount(for: category, in: january)
        let julyAmount = stopped.amount(for: category, in: july)
        let totalJulyAmount = stopped.amount(for: nil, in: july)

        #expect(none.isEmpty)
        #expect(januaryAmount == 30000)
        #expect(julyAmount == nil)
        #expect(totalJulyAmount == nil)
    }

    @Test
    func rejectsZero() async throws {
        let database = try AppDatabase.inMemory()

        let january = try #require(
            YearMonth(
                year: 2026,
                month: 1
            )
        )

        await #expect(throws: AppDatabase.BudgetWriteError.amountNotPositive) {
            try await database.setBudget(0, for: nil, from: january)
        }
    }
}
