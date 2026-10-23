enum ThemeHex {
    static func rgb(_ text: String) -> UInt32? {
        let digits = text.dropFirst()

        guard
            text.hasPrefix("#"),
            digits.count == 6,
            digits.allSatisfy(\.isHexDigit)
        else {
            return nil
        }

        return UInt32(digits, radix: 16)
    }

    static func text(_ rgb: UInt32) -> String {
        let digits = String(rgb, radix: 16, uppercase: true)
        return "#" + String(repeating: "0", count: 6 - digits.count) + digits
    }
}
