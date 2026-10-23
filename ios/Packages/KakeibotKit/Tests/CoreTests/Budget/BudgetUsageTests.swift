import Core
import Testing

struct BudgetUsageTests {
    @Test(arguments: try usageCases)
    func countsRemainingAndDaysLeft(fixture: UsageCase) {
        let usage = BudgetUsage(
            budget: fixture.budget,
            spent: fixture.spent,
            today: fixture.today,
            periodEnd: fixture.periodEnd
        )

        #expect(usage.remaining == fixture.remaining)
        #expect(usage.daysLeft == fixture.daysLeft)
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
        let daysLeft: Int
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
