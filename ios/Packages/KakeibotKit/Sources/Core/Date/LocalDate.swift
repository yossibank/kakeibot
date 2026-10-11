import Foundation

public struct LocalDate: Hashable, Comparable, Sendable {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    public let yearMonth: YearMonth
    public let day: Int

    public var year: Int {
        yearMonth.year
    }

    public var month: Int {
        yearMonth.month
    }

    public var weekday: Weekday {
        let sundayFirst = Self.calendar.component(.weekday, from: date)
        return Weekday.allCases[(sundayFirst + 5) % 7]
    }

    private var date: Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day))!
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year!, month: components.month!, day: components.day!)!
    }

    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        (lhs.yearMonth, lhs.day) < (rhs.yearMonth, rhs.day)
    }

    public func adding(days: Int) -> LocalDate {
        let moved = Self.calendar.date(byAdding: .day, value: days, to: date)!
        return LocalDate(moved, in: Self.calendar.timeZone)
    }

    public func periodMonth(monthStartDay: Int) -> YearMonth {
        precondition((1...31).contains(monthStartDay))
        if monthStartDay == 1 || day < yearMonth.clampedDate(day: monthStartDay).day {
            return yearMonth
        }
        return yearMonth.adding(months: 1)
    }

    public func week(startingOn weekStart: Weekday) -> ClosedRange<LocalDate> {
        let days = Weekday.allCases
        let offset = (days.firstIndex(of: weekday)! - days.firstIndex(of: weekStart)! + 7) % 7
        let start = adding(days: -offset)
        return start...start.adding(days: 6)
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
