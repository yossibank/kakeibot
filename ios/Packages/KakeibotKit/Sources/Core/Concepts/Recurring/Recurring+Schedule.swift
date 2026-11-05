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

    var finalDate: LocalDate? {
        guard let endDate else {
            return nil
        }

        let from = LocalDate(
            yearMonth: endDate.yearMonth.adding(months: -Self.finalSearchMonths),
            clampedDay: 1
        )

        return dates(from: from, through: endDate).last
    }

    var occurrenceCount: Int? {
        endDate.map { dates(from: startDate, through: $0).count }
    }

    var plannedTotal: Int? {
        endDate.map { end in
            dates(from: startDate, through: end)
                .map(scheduledAmount(paidOn:))
                .reduce(0, +)
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
            .map { Occurrence(scheduled: $0, date: holidayShift.apply(to: $0)) }
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

    func endDate(afterCount count: Int) -> LocalDate? {
        guard count > 0 else {
            return nil
        }

        var open = self
        open.endDate = nil

        let months = frequency == .monthly ? count + 2 : (count + 1) * 12
        let horizon = LocalDate(
            yearMonth: startDate.yearMonth.adding(months: months),
            clampedDay: 31
        )
        let dates = open.dates(from: startDate, through: horizon)

        return dates.count >= count ? dates[count - 1] : nil
    }

    func scheduledAmount(paidOn date: LocalDate) -> Int {
        guard
            let finalAmount,
            date == finalDate
        else {
            return amount
        }

        return finalAmount
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
        let scheduled = scheduledDate(of: date)
        return Occurrence(scheduled: scheduled, date: date)
    }

    func scheduledDate(of date: LocalDate) -> LocalDate {
        scheduledDate(shiftedTo: date) ?? date
    }

    func scheduledDate(shiftedTo date: LocalDate) -> LocalDate? {
        scheduledDates(shiftedInto: date.yearMonth).first { holidayShift.apply(to: $0) == date }
    }

    func scheduledDates(shiftedInto month: YearMonth) -> [LocalDate] {
        let previous = month.adding(months: -1)
        let next = month.adding(months: 1)

        return months(from: previous, through: next)
            .map { LocalDate(yearMonth: $0, clampedDay: day) }
            .filter { holidayShift.apply(to: $0).yearMonth == month }
    }

    func occurrenceMonth(of date: LocalDate) -> YearMonth {
        scheduledDate(of: date).yearMonth
    }
}

private extension Recurring {
    static let searchDays = 400
    static let finalSearchMonths = 13

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
            return indices.map { YearMonth(monthIndex: $0) }.filter { $0.month == month }
        }
    }
}
