import Core
import Testing

struct BudgetAmountTests {
    @Test(arguments: try amountCases)
    func usesLatestRowUpToMonth(fixture: AmountCase) {
        let food = EntryCategory.ID()
        let daily = EntryCategory.ID()
        let ids = ["food": food, "daily": daily]

        let budgets = fixture.budgets.map { row in
            Budget(
                categoryId: row.category.flatMap { ids[$0] },
                fromMonth: row.fromMonth,
                amount: row.amount
            )
        }

        let categoryId = fixture.category.flatMap { ids[$0] }
        let amount = budgets.amount(for: categoryId, in: fixture.month)

        #expect(amount == fixture.amount)
    }
}

extension BudgetAmountTests {
    struct AmountCase: Decodable, Sendable {
        let budgets: [Row]
        let category: String?
        let month: YearMonth
        let amount: Int?
    }

    struct Row: Decodable, Sendable {
        let category: String?
        let fromMonth: YearMonth
        let amount: Int?
    }
}

private extension BudgetAmountTests {
    static var amountCases: [AmountCase] {
        get throws {
            try Fixture.load("budget/budget-amount.json")
        }
    }
}
