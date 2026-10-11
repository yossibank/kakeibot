public struct YearMonth: Hashable, Sendable {
    public let year: Int
    public let month: Int

    public init?(
        year: Int,
        month: Int
    ) {
        guard (1...12).contains(month) else {
            return nil
        }

        self.year = year
        self.month = month
    }

    public init?(_ text: String) {
        guard
            let numbers = DateText.numbers(in: text, digits: [4, 2]),
            DateText.yearRange.contains(numbers[0])
        else {
            return nil
        }

        self.init(year: numbers[0], month: numbers[1])
    }
}

public extension YearMonth {
    var numberOfDays: Int {
        switch month {
        case 2: isLeapYear ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    func adding(months: Int) -> YearMonth {
        YearMonth(monthIndex: monthIndex + months)
    }

    func period(startingOn startDay: MonthStartDay) -> ClosedRange<LocalDate> {
        let startedLastMonth = startDay.period(startingIn: adding(months: -1))

        if startedLastMonth.upperBound.yearMonth == self {
            return startedLastMonth
        }

        return startDay.period(startingIn: self)
    }
}

extension YearMonth {
    var monthIndex: Int {
        year * 12 + month - 1
    }

    var firstDayNumber: Int {
        let previousYear = year - 1
        let daysBeforeYear = previousYear * 365 + Self.leapDays(through: previousYear)
        let leapDayThisYear = month > 2 && isLeapYear ? 1 : 0
        let daysBeforeMonth = Self.daysBeforeMonthInCommonYear[month - 1] + leapDayThisYear
        return daysBeforeYear + daysBeforeMonth
    }

    init(monthIndex: Int) {
        self.year = Self.floor(monthIndex, 12)
        self.month = monthIndex - year * 12 + 1
    }
}

private extension YearMonth {
    static let daysBeforeMonthInCommonYear = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

    var isLeapYear: Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    static func leapDays(through year: Int) -> Int {
        floor(year, 4) - floor(year, 100) + floor(year, 400)
    }

    static func floor(
        _ value: Int,
        _ divisor: Int
    ) -> Int {
        let (quotient, remainder) = value.quotientAndRemainder(dividingBy: divisor)
        return remainder < 0 ? quotient - 1 : quotient
    }
}

extension YearMonth: Comparable {
    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.monthIndex < rhs.monthIndex
    }
}

extension YearMonth: CustomStringConvertible {
    public var description: String {
        "\(DateText.padded(year, digits: 4))-\(DateText.padded(month, digits: 2))"
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
