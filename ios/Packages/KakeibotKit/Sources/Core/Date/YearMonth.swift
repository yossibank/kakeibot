public struct YearMonth: Hashable, Comparable, Sendable {
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

    private var isLeapYear: Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    private var firstDay: LocalDate {
        LocalDate(yearMonth: self, day: 1)!
    }

    private var lastDay: LocalDate {
        LocalDate(yearMonth: self, day: numberOfDays)!
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

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    public func adding(months: Int) -> YearMonth {
        let index = year * 12 + (month - 1) + months
        return YearMonth(year: index / 12, month: index % 12 + 1)!
    }

    public func period(monthStartDay: Int) -> ClosedRange<LocalDate> {
        precondition((1...31).contains(monthStartDay))

        if monthStartDay == 1 {
            return firstDay...lastDay
        }

        let start = adding(months: -1).clampedDate(day: monthStartDay)
        let end = clampedDate(day: monthStartDay).adding(days: -1)
        return start...end
    }

    func clampedDate(day: Int) -> LocalDate {
        LocalDate(yearMonth: self, day: min(day, numberOfDays))!
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
