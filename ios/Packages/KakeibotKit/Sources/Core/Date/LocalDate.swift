import Foundation

public struct LocalDate: Hashable, Sendable {
    private static let secondsPerDay = 86400
    private static let daysPer400Years = 146_097
    private static let unixEpochDayNumber = YearMonth(monthIndex: 1970 * 12).firstDayNumber

    public let yearMonth: YearMonth
    public let day: Int

    public var year: Int {
        yearMonth.year
    }

    public var month: Int {
        yearMonth.month
    }

    public var weekday: Weekday {
        Weekday(daysSinceMonday: dayNumber)
    }

    var dayNumber: Int {
        yearMonth.firstDayNumber + day - 1
    }

    public init?(
        yearMonth: YearMonth,
        day: Int
    ) {
        guard (1...yearMonth.numberOfDays).contains(day) else {
            return nil
        }

        self.yearMonth = yearMonth
        self.day = day
    }

    public init?(
        year: Int,
        month: Int,
        day: Int
    ) {
        guard let yearMonth = YearMonth(year: year, month: month) else {
            return nil
        }

        self.init(yearMonth: yearMonth, day: day)
    }

    public init?(_ text: String) {
        guard let numbers = DateText.numbers(in: text, digits: [4, 2, 2]) else {
            return nil
        }

        self.init(year: numbers[0], month: numbers[1], day: numbers[2])
    }

    public init(
        _ date: Date,
        in timeZone: TimeZone
    ) {
        let offset = TimeInterval(timeZone.secondsFromGMT(for: date))
        let localSeconds = date.timeIntervalSince1970 + offset
        let days = Int((localSeconds / TimeInterval(Self.secondsPerDay)).rounded(.down))

        self.init(dayNumber: Self.unixEpochDayNumber + days)
    }

    init(
        yearMonth: YearMonth,
        clampedDay day: Int
    ) {
        self.yearMonth = yearMonth
        self.day = min(max(day, 1), yearMonth.numberOfDays)
    }

    init(dayNumber: Int) {
        let estimatedYear = dayNumber * 400 / Self.daysPer400Years + 1
        var yearMonth = YearMonth(monthIndex: estimatedYear * 12)

        while yearMonth.firstDayNumber > dayNumber {
            yearMonth = yearMonth.adding(months: -1)
        }

        while yearMonth.adding(months: 1).firstDayNumber <= dayNumber {
            yearMonth = yearMonth.adding(months: 1)
        }

        self.yearMonth = yearMonth
        self.day = dayNumber - yearMonth.firstDayNumber + 1
    }

    public func adding(days: Int) -> LocalDate {
        LocalDate(dayNumber: dayNumber + days)
    }

    public func periodMonth(startingOn startDay: MonthStartDay) -> YearMonth {
        period(startingOn: startDay).upperBound.yearMonth
    }

    public func week(startingOn weekStart: Weekday) -> ClosedRange<LocalDate> {
        let offset = (weekday.daysSinceMonday - weekStart.daysSinceMonday + 7) % 7
        let start = adding(days: -offset)

        return start...start.adding(days: 6)
    }

    func period(startingOn startDay: MonthStartDay) -> ClosedRange<LocalDate> {
        let startedThisMonth = startDay.period(startingIn: yearMonth)

        if startedThisMonth.contains(self) {
            return startedThisMonth
        }

        return startDay.period(startingIn: yearMonth.adding(months: -1))
    }
}

extension LocalDate: Comparable {
    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        lhs.dayNumber < rhs.dayNumber
    }
}

extension LocalDate: CustomStringConvertible {
    public var description: String {
        "\(yearMonth)-\(DateText.padded(day, digits: 2))"
    }
}

extension LocalDate: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        guard let value = LocalDate(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(text)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
