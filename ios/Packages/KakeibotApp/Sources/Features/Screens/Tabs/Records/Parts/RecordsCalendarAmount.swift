import Core
import Foundation

enum RecordsCalendarAmount {
    static func text(
        _ amount: Int,
        type: Entry.Kind
    ) -> String {
        "\(sign(of: amount, type: type))\(number(abs(amount)))"
    }
}

private extension RecordsCalendarAmount {
    static let man = 10000
    static let tenthOfMan = 1000
    static let thousandMan = 10_000_000
    static let locale = Locale(identifier: "ja_JP")

    static func sign(
        of amount: Int,
        type: Entry.Kind
    ) -> String {
        if amount < 0 {
            "−"
        } else if type == .income {
            "+"
        } else {
            ""
        }
    }

    static func number(_ amount: Int) -> String {
        guard amount >= man else {
            return grouped(amount)
        }

        let tenths = (amount + tenthOfMan / 2) / tenthOfMan

        guard tenths < thousandMan / tenthOfMan else {
            return "\(grouped((amount + man / 2) / man))万"
        }

        return "\(tenths / 10).\(tenths % 10)万"
    }

    static func grouped(_ number: Int) -> String {
        number.formatted(.number.locale(locale))
    }
}
