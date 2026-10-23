public struct MonthStartDay: Hashable, Sendable {
    public let day: Int

    public init?(_ day: Int) {
        guard (1...31).contains(day) else {
            return nil
        }

        self.day = day
    }
}

public extension MonthStartDay {
    static var first: MonthStartDay {
        MonthStartDay(validDay: 1)
    }

    static var allDays: [MonthStartDay] {
        (1...31).map(MonthStartDay.init(validDay:))
    }

    var isLastDay: Bool {
        day == 31
    }
}

extension MonthStartDay {
    func date(in yearMonth: YearMonth) -> LocalDate {
        LocalDate(yearMonth: yearMonth, clampedDay: day)
    }

    func period(startingIn yearMonth: YearMonth) -> ClosedRange<LocalDate> {
        let start = date(in: yearMonth)
        let end = date(in: yearMonth.adding(months: 1)).adding(days: -1)

        return start...end
    }
}

private extension MonthStartDay {
    init(validDay day: Int) {
        self.day = day
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
