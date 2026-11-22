import Foundation

public enum ReviewInsight {
    private static let locale = Locale(identifier: "ja_JP")

    public static func yen(_ amount: Int) -> String {
        "\(amount.formatted(.number.locale(locale)))円"
    }
}
