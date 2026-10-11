public struct YearMonth: Hashable, Sendable {
    public let year: Int
    public let month: Int

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
        guard let numbers = DateText.numbers(in: text, digits: [4, 2]) else {
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
        let leapDays = previousYear / 4 - previousYear / 100 + previousYear / 400

        let daysBeforeMonth = (1..<month).reduce(0) { total, earlierMonth in
            total + YearMonth(monthIndex: year * 12 + earlierMonth - 1).numberOfDays
        }

        return previousYear * 365 + leapDays + daysBeforeMonth
    }

    init(monthIndex: Int) {
        let (quotient, remainder) = monthIndex.quotientAndRemainder(dividingBy: 12)
        let borrow = remainder < 0 ? 1 : 0
        self.year = quotient - borrow
        self.month = remainder + borrow * 12 + 1
    }
}

private extension YearMonth {
    var isLeapYear: Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
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
