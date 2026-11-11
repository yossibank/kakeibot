import Core
@testable import DesignSystem
import Testing

struct AmountTextTests {
    @Test(arguments: [
        (999_999, Entry.Kind.expense, "¥999,999"),
        (1_000_000, Entry.Kind.expense, "100万円"),
        (9_886_163, Entry.Kind.expense, "988万円"),
        (12_345_678, Entry.Kind.income, "+1,234万円"),
        (3000, Entry.Kind.income, "+¥3,000")
    ])
    func shortensLargeAmounts(amount: Int, type: Entry.Kind, expected: String) {
        #expect(AmountText.compactText(amount, type: type) == expected)
    }
}
