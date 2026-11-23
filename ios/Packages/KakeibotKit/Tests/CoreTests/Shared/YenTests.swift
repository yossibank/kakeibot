import Core
import Testing

struct YenTests {
    @Test(arguments: [
        (980, Entry.Kind?.none, Yen.Sign.auto, "¥980"),
        (250_000, Entry.Kind?.some(.income), Yen.Sign.auto, "+¥250,000"),
        (3000, Entry.Kind?.some(.transfer), Yen.Sign.auto, "¥3,000"),
        (-24800, Entry.Kind?.none, Yen.Sign.auto, "−¥24,800"),
        (1200, Entry.Kind?.none, Yen.Sign.plus, "+¥1,200"),
        (0, Entry.Kind?.none, Yen.Sign.plus, "¥0"),
        (-500, Entry.Kind?.none, Yen.Sign.plus, "−¥500")
    ])
    func marksTheSignBeforeTheYenMark(
        amount: Int,
        type: Entry.Kind?,
        sign: Yen.Sign,
        expected: String
    ) {
        #expect(Yen.text(amount, type: type, sign: sign) == expected)
    }

    @Test(arguments: [
        (999_999, Entry.Kind.expense, "¥999,999"),
        (1_000_000, Entry.Kind.expense, "100万円"),
        (9_886_163, Entry.Kind.expense, "988万円"),
        (12_345_678, Entry.Kind.income, "+1,234万円"),
        (3000, Entry.Kind.income, "+¥3,000")
    ])
    func shortensLargeAmounts(amount: Int, type: Entry.Kind, expected: String) {
        #expect(Yen.compactText(amount, type: type) == expected)
    }
}
