import Foundation

public enum Yen {
    public enum Sign: Sendable {
        case auto
        case plus
    }

    public static let compactUnit = "万円"

    private static let locale = Locale(identifier: "ja_JP")
    private static let compactFloor = 1_000_000

    public static func text(
        _ amount: Int,
        type: Entry.Kind? = nil,
        sign: Sign = .auto
    ) -> String {
        let number = abs(amount).formatted(.number.locale(locale))
        return "\(mark(of: amount, type: type, sign: sign))¥\(number)"
    }

    public static func compactText(
        _ amount: Int,
        type: Entry.Kind? = nil,
        sign: Sign = .auto
    ) -> String {
        guard abs(amount) >= compactFloor else {
            return text(amount, type: type, sign: sign)
        }

        let number = (abs(amount) / 10000).formatted(.number.locale(locale))

        return "\(mark(of: amount, type: type, sign: sign))\(number)\(compactUnit)"
    }

    private static func mark(
        of amount: Int,
        type: Entry.Kind?,
        sign: Sign
    ) -> String {
        if amount < 0 {
            "−"
        } else if type == .income || (sign == .plus && amount > 0) {
            "+"
        } else {
            ""
        }
    }
}
