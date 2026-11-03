public struct MonthStartDay: Hashable, Sendable {
    public let day: Int
    public let shift: HolidayShift

    public init?(
        _ day: Int,
        shift: HolidayShift = .none
    ) {
        guard (1...31).contains(day) else {
            return nil
        }

        self.day = day
        self.shift = shift
    }
}

public extension MonthStartDay {
    static var first: MonthStartDay {
        MonthStartDay(validDay: 1)
    }

    static var allDays: [MonthStartDay] {
        (1...31).map { MonthStartDay(validDay: $0) }
    }

    var isLastDay: Bool {
        day == 31
    }

    func shifted(by shift: HolidayShift) -> MonthStartDay {
        MonthStartDay(validDay: day, shift: shift)
    }
}

extension MonthStartDay {
    func date(in yearMonth: YearMonth) -> LocalDate {
        let date = LocalDate(yearMonth: yearMonth, clampedDay: day)
        return shift.apply(to: date)
    }

    func period(startingIn yearMonth: YearMonth) -> ClosedRange<LocalDate> {
        let start = date(in: yearMonth)
        let nextMonth = yearMonth.adding(months: 1)
        let end = date(in: nextMonth).adding(days: -1)
        return start...end
    }

    func periodMonth(startingIn yearMonth: YearMonth) -> YearMonth {
        day == 1 ? yearMonth : yearMonth.adding(months: 1)
    }

    func startMonth(ofPeriodIn month: YearMonth) -> YearMonth {
        day == 1 ? month : month.adding(months: -1)
    }

    func startMonth(ofPeriodContaining date: LocalDate) -> YearMonth {
        let candidates = (-2...1).map { date.yearMonth.adding(months: $0) }
        return candidates.first { period(startingIn: $0).contains(date) } ?? date.yearMonth
    }
}

private extension MonthStartDay {
    init(
        validDay day: Int,
        shift: HolidayShift = .none
    ) {
        self.day = day
        self.shift = shift
    }
}

extension MonthStartDay: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let day = try container.decode(Int.self)

        guard let value = MonthStartDay(day) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid month start day: \(day)"
            )
        }

        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(day)
    }
}
