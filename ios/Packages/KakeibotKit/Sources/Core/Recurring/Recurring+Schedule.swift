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

        let first = lower.yearMonth.adding(months: -1)
        let last = upper.yearMonth.adding(months: 1)

        return months(from: first, through: last)
            .map { shifted(LocalDate(yearMonth: $0, clampedDay: day)) }
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

    func isRecorded(
        by entry: Entry,
        on date: LocalDate
    ) -> Bool {
        guard
            entry.recurringId == id,
            let recordedDate = entry.recurringDate
        else {
            return false
        }

        return occurrenceMonth(of: recordedDate) == occurrenceMonth(of: date)
    }

    func scheduledDate(of date: LocalDate) -> LocalDate {
        let months = months(
            from: date.yearMonth.adding(months: -1),
            through: date.yearMonth.adding(months: 1)
        )

        let scheduled = months
            .map { LocalDate(yearMonth: $0, clampedDay: day) }
            .first { shifted($0) == date }

        return scheduled ?? date
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
