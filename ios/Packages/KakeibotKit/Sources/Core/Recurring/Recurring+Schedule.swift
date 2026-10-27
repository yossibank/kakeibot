public extension Recurring {
    struct Occurrence: Hashable, Sendable {
        public let scheduled: LocalDate
        public let date: LocalDate

        public init(
            scheduled: LocalDate,
            date: LocalDate
        ) {
            self.scheduled = scheduled
            self.date = date
        }
    }

    func occurrences(
        from start: LocalDate,
        through end: LocalDate
    ) -> [Occurrence] {
        let lower = max(start, startDate)
        let upper = endDate.map { min(end, $0) } ?? end

        guard lower <= upper else {
            return []
        }

        let first = lower.yearMonth.adding(months: -1)
        let last = upper.yearMonth.adding(months: 1)

        return months(from: first, through: last)
            .map { LocalDate(yearMonth: $0, clampedDay: day) }
            .map { Occurrence(scheduled: $0, date: shifted($0)) }
            .filter { lower <= $0.date && $0.date <= upper }
    }

    func dates(
        from start: LocalDate,
        through end: LocalDate
    ) -> [LocalDate] {
        occurrences(from: start, through: end).map(\.date)
    }

    func pendingOccurrences(through today: LocalDate) -> [Occurrence] {
        let start = generatedUntil.map { $0.adding(days: 1) } ?? startDate
        return occurrences(from: start, through: today)
    }

    func nextDate(onOrAfter date: LocalDate) -> LocalDate? {
        let horizon = date.adding(days: Self.searchDays)
        return dates(from: date, through: horizon).first
    }

    func isRecorded(
        by entry: Entry,
        scheduled: LocalDate
    ) -> Bool {
        guard
            entry.recurringId == id,
            let recorded = entry.recurringDate
        else {
            return false
        }

        return recorded.yearMonth == scheduled.yearMonth
    }

    func occurrence(on date: LocalDate) -> Occurrence {
        Occurrence(scheduled: scheduledDate(of: date), date: date)
    }

    func scheduledDate(of date: LocalDate) -> LocalDate {
        scheduledDate(shiftedTo: date) ?? date
    }

    func scheduledDate(shiftedTo date: LocalDate) -> LocalDate? {
        scheduledDates(shiftedInto: date.yearMonth)
            .first { shifted($0) == date }
    }

    func scheduledDates(shiftedInto month: YearMonth) -> [LocalDate] {
        months(from: month.adding(months: -1), through: month.adding(months: 1))
            .map { LocalDate(yearMonth: $0, clampedDay: day) }
            .filter { shifted($0).yearMonth == month }
    }

    func occurrenceMonth(of date: LocalDate) -> YearMonth {
        scheduledDate(of: date).yearMonth
    }
}

private extension Recurring {
    static let searchDays = 400

    func shifted(_ date: LocalDate) -> LocalDate {
        let step = switch holidayShift {
        case .none: 0
        case .previous: -1
        case .next: 1
        }

        guard step != 0 else {
            return date
        }

        var shifted = date

        while Holiday.isDayOff(shifted) {
            shifted = shifted.adding(days: step)
        }

        return shifted
    }

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
