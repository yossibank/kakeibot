import Core
import DesignSystem

enum BillText {
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

    static func balance(_ bill: CardBill) -> String {
        guard bill.shortage == 0 else {
            return shortage(bill.shortage)
        }

        let before = AmountText.text(bill.balanceBefore)
        let after = AmountText.text(bill.balanceAfter)

        return "\(before) → \(after)"
    }
}
