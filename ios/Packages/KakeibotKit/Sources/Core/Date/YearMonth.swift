public struct YearMonth: Hashable, Sendable {
    public let year: Int
    public let month: Int

    public var numberOfDays: Int {
        switch month {
        case 2:
            isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            30
        default:
            31
        }
    }

    var monthIndex: Int {
        year * 12 + month - 1
    }

    private var isLeapYear: Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    public init?(
        year: Int,
        month: Int
    ) {
        guard (1...9999).contains(year), (1...12).contains(month) else {
            return nil
        }

        self.year = year
        self.month = month
    }

    public init?(_ text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)

        guard
            parts.count == 2,
            let year = Int(asciiDigits: parts[0], count: 4),
            let month = Int(asciiDigits: parts[1], count: 2)
        else {
            return nil
        }

        self.init(year: year, month: month)
    }

    init(monthIndex: Int) {
        let (quotient, remainder) = monthIndex.quotientAndRemainder(dividingBy: 12)
        let borrow = remainder < 0 ? 1 : 0

        self.year = quotient - borrow
        self.month = remainder + borrow * 12 + 1
    }

    public func adding(months: Int) -> YearMonth {
        YearMonth(monthIndex: monthIndex + months)
    }

    public func period(monthStartDay: Int) -> ClosedRange<LocalDate> {
        precondition((1...31).contains(monthStartDay))

        if monthStartDay == 1 {
            let first = LocalDate(yearMonth: self, clampedDay: 1)
            let last = LocalDate(yearMonth: self, clampedDay: numberOfDays)

            return first...last
        }

        let start = LocalDate(yearMonth: adding(months: -1), clampedDay: monthStartDay)
        let end = LocalDate(yearMonth: self, clampedDay: monthStartDay).adding(days: -1)

        return start...end
    }
}

extension YearMonth: Comparable {
    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.monthIndex < rhs.monthIndex
    }
}

extension YearMonth: CustomStringConvertible {
    public var description: String {
        "\(Int.paddedText(year, count: 4))-\(Int.paddedText(month, count: 2))"
    }
}

extension YearMonth: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let value = YearMonth(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid year-month: \(text)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
