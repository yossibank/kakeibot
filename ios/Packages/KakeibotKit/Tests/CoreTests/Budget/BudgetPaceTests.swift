import Core
import Testing

struct BudgetPaceTests {
    @Test(arguments: try paceCases)
    func projectsLeftAtPeriodEnd(fixture: PaceCase) {
        let pace = BudgetPace(
            budget: fixture.budget,
            spent: fixture.spent,
            fixedSpent: fixture.fixedSpent ?? 0,
            upcoming: fixture.upcoming ?? 0,
            today: fixture.today,
            period: fixture.periodStart...fixture.periodEnd
        )

        #expect(pace.projectedLeft == fixture.projectedLeft)
    }
}

extension BudgetPaceTests {
    struct PaceCase: Decodable, Sendable {
        let budget: Int
        let spent: Int
        let fixedSpent: Int?
        let upcoming: Int?
        let today: LocalDate
        let periodStart: LocalDate
        let periodEnd: LocalDate
        let projectedLeft: Int
    }
}

private extension BudgetPaceTests {
    static var paceCases: [PaceCase] {
        get throws {
            try Fixture.load("budget/budget-pace.json")
        }
    }
}
