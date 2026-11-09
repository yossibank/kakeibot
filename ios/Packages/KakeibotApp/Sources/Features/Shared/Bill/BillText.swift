import Core
import DesignSystem

enum BillText {
    static let openTag = "途中"
    static let openNote = "締め日までは、今日までに記録した利用分です。締め日を過ぎると額が決まります。"

    static func days(
        until date: LocalDate,
        today: LocalDate
    ) -> String {
        switch today.days(until: date) {
        case ...0: "今日"
        case 1: "明日"
        case let days: "あと \(days) 日"
        }
    }

    static func shortage(_ amount: Int) -> String {
        "残高が \(AmountText.text(amount)) 足りません"
    }

    static func source(_ name: String?) -> String {
        "\(name ?? "口座")から"
    }

    static func page(_ month: YearMonth) -> String {
        "\(month.month)月払い"
    }

    static func total(of page: BillPage) -> String {
        let amount = AmountText.text(page.total)
        return page.isOpen ? "今のところ \(amount)" : "合計 \(amount)"
    }

    static func paid(on date: LocalDate) -> String {
        "\(date.monthDayText) 払い"
    }

    static func closing(
        of bill: CardBill,
        today: LocalDate
    ) -> String? {
        guard let closing = bill.period?.upperBound else {
            return nil
        }

        let days = Self.days(until: closing, today: today)

        return "\(closing.monthDayText) 締め · \(days)で決まる"
    }

    static func balance(_ bill: CardBill) -> String {
        guard bill.shortage == 0 || bill.isOpen else {
            return shortage(bill.shortage)
        }

        let before = AmountText.text(bill.balanceBefore)
        let after = AmountText.text(bill.balanceAfter)

        return "\(before) → \(after)"
    }
}
