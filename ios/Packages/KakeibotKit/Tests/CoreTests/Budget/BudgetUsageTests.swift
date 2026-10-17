import Core
import Testing

struct BudgetUsageTests {
    @Test(arguments: try usageCases)
    func countsRemainingAndPerDay(fixture: UsageCase) {
        let usage = BudgetUsage(
            budget: fixture.budget,
            spent: fixture.spent,
            today: fixture.today,
            periodEnd: fixture.periodEnd
        )

        #expect(usage.remaining == fixture.remaining)
        #expect(usage.perDay == fixture.perDay)
        #expect(usage.isOver == fixture.isOver)
        #expect(usage.isNearLimit == fixture.isNearLimit)
    }
}

extension BudgetUsageTests {
    struct UsageCase: Decodable, Sendable {
        let budget: Int
        let spent: Int
        let today: LocalDate
        let periodEnd: LocalDate
        let remaining: Int
        let perDay: Int
        let isOver: Bool
        let isNearLimit: Bool
    }
}

private extension BudgetUsageTests {
    static var usageCases: [UsageCase] {
        get throws {
            try Fixture.load("budget/budget-usage.json")
        }
    }
}
