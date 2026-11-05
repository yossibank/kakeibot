import Core
import Testing

struct RepaymentPlanTests {
    @Test(arguments: try planCases)
    func plansCountAndFinalAmount(fixture: PlanCase) throws {
        let owed = fixture.owed

        let plan = try #require(RepaymentPlan(
            owed: owed,
            amount: fixture.amount,
            count: fixture.count
        ))

        #expect(plan.count == fixture.expectedCount)
        #expect(plan.finalAmount == fixture.finalAmount)
        #expect(plan.gap == fixture.gap)
    }

    @Test(arguments: [(0, 16235), (-1, 16235), (3_896_752, 0)])
    func hasNoPlanWithoutOwedOrAmount(owed: Int, amount: Int) {
        let plan = RepaymentPlan(owed: owed, amount: amount)

        #expect(plan == nil)
    }
}

extension RepaymentPlanTests {
    struct PlanCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let owed: Int
        let amount: Int
        let count: Int?
        let expectedCount: Int
        let finalAmount: Int?
        let gap: Int

        var testDescription: String {
            summary
        }
    }
}

private extension RepaymentPlanTests {
    static var planCases: [PlanCase] {
        get throws {
            try CoreFixture.cases("recurring/repayment-plan.json")
        }
    }
}
