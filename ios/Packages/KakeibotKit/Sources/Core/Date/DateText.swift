enum DateText {}

extension DateText {
    static let yearRange = 1...9999

    static func numbers(
        in text: String,
        digits: [Int]
    ) -> [Int]? {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)

        guard parts.count == digits.count else {
            return nil
        }

        let numbers = zip(parts, digits).compactMap { number(in: $0, digits: $1) }

        return numbers.count == digits.count ? numbers : nil
    }

    static func padded(
        _ value: Int,
        digits: Int
    ) -> String {
        let text = String(value.magnitude)
        let padding = String(repeating: "0", count: max(0, digits - text.count))
        let sign = value < 0 ? "-" : ""
        return sign + padding + text
    }
}

private extension DateText {
    static func number(
        in part: Substring,
        digits: Int
    ) -> Int? {
        let isASCIIDigits = part.utf8.allSatisfy {
            (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0)
        }

        guard part.utf8.count == digits, isASCIIDigits else {
            return nil
        }

        return Int(part)
    }
}
