public struct ReviewPeriod: Hashable, Sendable {
    public let scale: Scale
    public let monthStartDay: MonthStartDay
    public let weekStart: Weekday
    public let range: ClosedRange<LocalDate>

    public init(
        scale: Scale,
        containing date: LocalDate,
        monthStartDay: MonthStartDay,
        weekStart: Weekday
    ) {
        self.scale = scale
        self.monthStartDay = monthStartDay
        self.weekStart = weekStart

        switch scale {
        case .week:
            self.range = date.week(startingOn: weekStart)
        case .month:
            self.range = date.period(startingOn: monthStartDay)
        case .year:
            let month = date.periodMonth(startingOn: monthStartDay)
            let december = month.adding(months: 12 - month.month)
            let january = december.adding(months: -11)
            let start = january.period(startingOn: monthStartDay).lowerBound
            let end = december.period(startingOn: monthStartDay).upperBound
            self.range = start...end
        }
    }
}

public extension ReviewPeriod {
    enum Scale: String, CaseIterable, Codable, Sendable {
        case week
        case month
        case year
    }

    var previous: ReviewPeriod {
        adding(-1)
    }

    func adding(_ count: Int) -> ReviewPeriod {
        let date: LocalDate

        switch scale {
        case .week:
            date = range.lowerBound.adding(days: 7 * count)
        case .month:
            let month = range.upperBound.yearMonth.adding(months: count)
            date = month.period(startingOn: monthStartDay).lowerBound
        case .year:
            let month = range.upperBound.yearMonth.adding(months: 12 * count)
            date = month.period(startingOn: monthStartDay).lowerBound
        }

        return ReviewPeriod(
            scale: scale,
            containing: date,
            monthStartDay: monthStartDay,
            weekStart: weekStart
        )
    }
}
