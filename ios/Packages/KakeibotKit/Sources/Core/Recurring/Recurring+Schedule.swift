public extension Recurring {
    func dates(
        from start: LocalDate,
        through end: LocalDate
    ) -> [LocalDate] {
        let lower = max(start, startDate)
        let upper = endDate.map { min(end, $0) } ?? end

        guard lower <= upper else {
            return []
        }

        return months(from: lower.yearMonth, through: upper.yearMonth)
            .map { LocalDate(yearMonth: $0, clampedDay: day) }
            .filter { lower <= $0 && $0 <= upper }
    }

    func pendingDates(through today: LocalDate) -> [LocalDate] {
        let start = generatedUntil.map { $0.adding(days: 1) } ?? startDate
        return dates(from: start, through: today)
    }

    func nextDate(onOrAfter date: LocalDate) -> LocalDate? {
        let horizon = date.adding(days: Self.searchDays)
        return dates(from: date, through: horizon).first
    }
}

private extension Recurring {
    static let searchDays = 400

    func months(
        from first: YearMonth,
        through last: YearMonth
    ) -> [YearMonth] {
        let indices = first.monthIndex...last.monthIndex

        switch frequency {
        case .monthly:
            return indices.map { YearMonth(monthIndex: $0) }
        case .yearly:
            let month = month ?? 1

            return indices
                .map { YearMonth(monthIndex: $0) }
                .filter { $0.month == month }
        }
    }
}
