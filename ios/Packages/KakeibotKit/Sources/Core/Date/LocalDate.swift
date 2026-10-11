import Foundation

public struct LocalDate: Hashable, Sendable {
    private static let secondsPerDay = 86400
    private static let unixEpochDayNumber = daysBefore(year: 1970)

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
        let january = YearMonth(monthIndex: year * 12)
        let daysBeforeMonth = (0..<(month - 1)).reduce(0) { total, offset in
            total + january.adding(months: offset).numberOfDays
        }

        return Self.daysBefore(year: year) + daysBeforeMonth + day - 1
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
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)

        guard
            parts.count == 3,
            let year = Int(asciiDigits: parts[0], count: 4),
            let month = Int(asciiDigits: parts[1], count: 2),
            let day = Int(asciiDigits: parts[2], count: 2)
        else {
            return nil
        }

        self.init(year: year, month: month, day: day)
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
        var year = dayNumber * 400 / 146_097 + 1

        while Self.daysBefore(year: year + 1) <= dayNumber {
            year += 1
        }

        while Self.daysBefore(year: year) > dayNumber {
            year -= 1
        }

        var yearMonth = YearMonth(monthIndex: year * 12)
        var remainingDays = dayNumber - Self.daysBefore(year: year)

        while remainingDays >= yearMonth.numberOfDays {
            remainingDays -= yearMonth.numberOfDays
            yearMonth = yearMonth.adding(months: 1)
        }

        self.yearMonth = yearMonth
        self.day = remainingDays + 1
    }

    private static func daysBefore(year: Int) -> Int {
        let previousYear = year - 1
        let leapDays = previousYear / 4 - previousYear / 100 + previousYear / 400

        return previousYear * 365 + leapDays
    }

    public func adding(days: Int) -> LocalDate {
        LocalDate(dayNumber: dayNumber + days)
    }

    public func periodMonth(monthStartDay: Int) -> YearMonth {
        precondition((1...31).contains(monthStartDay))

        if monthStartDay == 1 || day < min(monthStartDay, yearMonth.numberOfDays) {
            return yearMonth
        }

        return yearMonth.adding(months: 1)
    }

    public func week(startingOn weekStart: Weekday) -> ClosedRange<LocalDate> {
        let offset = (weekday.daysSinceMonday - weekStart.daysSinceMonday + 7) % 7
        let start = adding(days: -offset)

        return start...start.adding(days: 6)
    }
}

extension LocalDate: Comparable {
    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        lhs.dayNumber < rhs.dayNumber
    }
}

extension LocalDate: CustomStringConvertible {
    public var description: String {
        "\(yearMonth)-\(Int.paddedText(day, count: 2))"
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
