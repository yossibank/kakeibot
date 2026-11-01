import Core
import Testing

struct BudgetCarryoverTests {
    @Test
    func returnsZeroWithoutStart() throws {
        let budgets = try [budget("2026-01", 50000)]
        let month = try #require(YearMonth("2026-10"))

        let result = budgets.carryover(into: month, from: nil) { _ in 0 }

        #expect(result == 0)
    }

    @Test
    func accumulatesRemainingOfEachMonth() throws {
        let budgets = try [budget("2026-01", 50000)]
        let start = try #require(YearMonth("2026-07"))
        let month = try #require(YearMonth("2026-10"))
        let expenses = ["2026-07": 40000, "2026-08": 50000, "2026-09": 30000]

        let result = budgets.carryover(into: month, from: start) { expenses[$0.description] ?? 0 }

        #expect(result == 30000)
    }

    @Test
    func subtractsOverspentMonth() throws {
        let budgets = try [budget("2026-01", 50000)]
        let start = try #require(YearMonth("2026-08"))
        let month = try #require(YearMonth("2026-10"))
        let expenses = ["2026-08": 70000, "2026-09": 40000]

        let result = budgets.carryover(into: month, from: start) { expenses[$0.description] ?? 0 }

        #expect(result == -10000)
    }

    @Test
    func restartsAfterMonthWithoutBudget() throws {
        let budgets = try [
            budget("2026-01", 50000),
            budget("2026-08", nil),
            budget("2026-09", 50000)
        ]

        let start = try #require(YearMonth("2026-07"))
        let month = try #require(YearMonth("2026-11"))

        let result = budgets.carryover(into: month, from: start) { _ in 10000 }

        #expect(result == 80000)
    }

    @Test
    func returnsZeroWhenMonthIsNotAfterStart() throws {
        let budgets = try [budget("2026-01", 50000)]
        let start = try #require(YearMonth("2026-10"))
        let before = try #require(YearMonth("2026-09"))

        let same = budgets.carryover(into: start, from: start) { _ in 0 }
        let earlier = budgets.carryover(into: before, from: start) { _ in 0 }

        #expect(same == 0)
        #expect(earlier == 0)
    }

    @Test
    func addsStartMonthFromNextMonth() throws {
        let budgets = try [budget("2026-01", 50000)]
        let start = try #require(YearMonth("2026-10"))
        let next = try #require(YearMonth("2026-11"))

        let result = budgets.carryover(into: next, from: start) { _ in 20000 }

        #expect(result == 30000)
    }

    @Test
    func ignoresCategoryBudgets() throws {
        let food = EntryCategory.ID()
        let start = try #require(YearMonth("2026-09"))
        let month = try #require(YearMonth("2026-10"))

        let budgets = try [
            budget("2026-01", 50000),
            Budget(categoryId: food, fromMonth: #require(YearMonth("2026-01")), amount: 10000)
        ]

        let result = budgets.carryover(into: month, from: start) { _ in 20000 }

        #expect(result == 30000)
    }
}

private extension BudgetCarryoverTests {
    func budget(_ month: String, _ amount: Int?) throws -> Budget {
        try Budget(
            categoryId: nil,
            fromMonth: #require(YearMonth(month)),
            amount: amount
        )
    }
}
