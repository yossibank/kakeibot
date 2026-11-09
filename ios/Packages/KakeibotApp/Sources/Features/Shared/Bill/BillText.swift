import Core
import DesignSystem

enum BillText {
    static let estimate = "見込み"
    static let settled = "確定"

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

    static func note(of pages: [BillPage]) -> String? {
        guard
            pages.count == 1,
            let page = pages.first
        else {
            return nil
        }

        return "\(Self.page(page.month)) \(AmountText.text(page.total))"
    }

    static func count(of page: BillPage) -> String {
        let count = "\(page.bills.count) 件"

        switch page.openCount {
        case 0: return count
        case page.bills.count: return "\(count) · すべて\(estimate)"
        case let open: return "\(count) · \(open) 件は\(estimate)"
        }
    }

    static func estimate(of bill: CardBill) -> String {
        guard let closing = bill.period?.upperBound else {
            return estimate
        }

        return "\(estimate) · \(closing.monthDayText) 締め"
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
