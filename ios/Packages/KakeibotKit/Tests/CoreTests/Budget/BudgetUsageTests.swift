import Core
import Testing

struct BudgetUsageTests {
    @Test(arguments: try usageCases)
    func countsRemainingAndPerDay(fixture: UsageCase) {
        let usage = BudgetUsage(
            budget: fixture.budget,
            spent: fixture.spent,
            upcoming: fixture.upcoming ?? 0,
            today: fixture.today,
            periodEnd: fixture.periodEnd
        )

        #expect(usage.remaining == fixture.remaining)
        #expect(usage.perDay == fixture.perDay)
        #expect(usage.isOver == fixture.isOver)
        #expect(usage.isNearLimit == fixture.isNearLimit)

        let spentToday = fixture.spentToday ?? 0
        let todayRemaining = usage.todayRemaining(spentToday: spentToday)

        #expect(todayRemaining == fixture.todayRemaining)
    }
}

extension BudgetUsageTests {
    struct UsageCase: Decodable, Sendable {
        let budget: Int
        let spent: Int
        let upcoming: Int?
        let today: LocalDate
        let periodEnd: LocalDate
        let remaining: Int
        let perDay: Int
        let isOver: Bool
        let isNearLimit: Bool
        let spentToday: Int?
        let todayRemaining: Int
    }
}

private extension BudgetUsageTests {
    static var usageCases: [UsageCase] {
        get throws {
            try Fixture.load("budget/budget-usage.json")
        }
    }
}
