import Core
@testable import Features
import Testing

struct RecordsCalendarAmountTests {
    @Test(arguments: [
        (0, "0"),
        (2400, "2,400"),
        (9999, "9,999"),
        (10000, "1.0万"),
        (12340, "1.2万"),
        (99950, "10.0万"),
        (1_237_907, "123.8万"),
        (9_876_543, "987.7万"),
        (9_999_449, "999.9万"),
        (9_999_500, "1,000万"),
        (12_345_678, "1,235万"),
        (123_456_789, "12,346万")
    ])
    func shortensExpense(amount: Int, expected: String) {
        let text = RecordsCalendarAmount.text(amount, type: .expense)
        #expect(text == expected)
    }

    @Test(arguments: [
        (2400, "+2,400"),
        (250_000, "+25.0万"),
        (12_345_678, "+1,235万")
    ])
    func signsIncome(amount: Int, expected: String) {
        let text = RecordsCalendarAmount.text(amount, type: .income)
        #expect(text == expected)
    }

    @Test
    func signsNegativeAmount() {
        let text = RecordsCalendarAmount.text(-12340, type: .expense)
        #expect(text == "−1.2万")
    }
}
