import Foundation

public enum ReviewYen {
    private static let locale = Locale(identifier: "ja_JP")

    public static func number(_ amount: Int) -> String {
        amount.formatted(.number.locale(locale))
    }

    public static func text(_ amount: Int) -> String {
        "\(number(amount))円"
    }
}
