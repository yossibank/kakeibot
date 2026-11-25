import Core
import DesignSystem
@testable import Features
import Testing

struct ReviewTextTests {
    @Test(arguments: try shareCases)
    func namesShares(fixture: ShareCase) {
        let texts = ReviewText.shares(fixture.amounts)
        #expect(texts == fixture.texts)
    }

    @Test(arguments: [
        (6000, "予算の 15%"),
        (40000, "予算の 100%"),
        (41200, "¥1,200 オーバー")
    ])
    func namesBudgetUsage(spent: Int, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let end = try #require(LocalDate("2026-10-31"))

        let usage = BudgetUsage(
            budget: 40000,
            spent: spent,
            today: today,
            periodEnd: end
        )

        let text = ReviewText.budget(usage)
        #expect(text == expected)
    }

    @Test(arguments: try balanceCases)
    func signsBalance(fixture: BalanceCase) {
        #expect(Yen.text(fixture.amount, sign: .plus) == fixture.text)
        #expect(ReviewText.balanceTitle(fixture.amount) == fixture.title)
    }
}

extension ReviewTextTests {
    struct ShareCase: Decodable, Sendable {
        let summary: String
        let amounts: [Int]
        let texts: [String?]
    }

    struct BalanceCase: Decodable, Sendable {
        let summary: String
        let amount: Int
        let title: String
        let text: String
    }

    static var shareCases: [ShareCase] {
        get throws {
            try FeaturesFixture.cases("review/review-share-text.json")
        }
    }

    static var balanceCases: [BalanceCase] {
        get throws {
            try FeaturesFixture.cases("review/review-balance-text.json")
        }
    }
}
