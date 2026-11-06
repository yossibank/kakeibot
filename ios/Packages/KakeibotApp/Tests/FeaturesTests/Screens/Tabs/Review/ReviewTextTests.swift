import Core
import DesignSystem
@testable import Features
import Testing

struct ReviewTextTests {
    @Test(arguments: [
        ([42400, 36400, 21200], ["43%", "36%", "21%"]),
        ([11_000_000, 5880], ["99.9%", "1%未満"]),
        ([1000, 5], ["99.5%", "1%未満"]),
        ([99, 1], ["99%", "1%"]),
        ([100], ["100%"]),
        ([500, 0], ["100%", "0%"]),
        ([0, 0], ["0%", "0%"])
    ])
    func namesShares(amounts: [Int], expected: [String]) {
        let texts = ReviewText.shares(amounts)
        #expect(texts == expected)
    }

    @Test(arguments: [
        (6000, "予算 ¥40,000 の 15%"),
        (40000, "予算 ¥40,000 の 100%"),
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

    @Test(arguments: [
        (1_219_768, "+¥1,219,768", "収支 · 黒字"),
        (-24800, "−¥24,800", "収支 · 赤字"),
        (0, "¥0", "収支")
    ])
    func signsBalance(amount: Int, expected: String, title: String) {
        #expect(AmountText.text(amount, sign: .plus) == expected)
        #expect(ReviewText.balanceTitle(amount) == title)
    }
}
