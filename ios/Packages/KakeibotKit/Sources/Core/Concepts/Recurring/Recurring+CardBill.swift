public extension Recurring {
    static let billChoiceCount = 3

    static func billText(paidOn date: LocalDate) -> String {
        "\(date.month)/\(date.day)払い"
    }

    func billingPeriod(paidOn date: LocalDate) -> ClosedRange<LocalDate>? {
        guard let closingDay else {
            return nil
        }

        let scheduled = scheduledDate(of: date)

        let closingMonth = day > closingDay
            ? scheduled.yearMonth
            : scheduled.yearMonth.adding(months: -1)

        let closing = LocalDate(yearMonth: closingMonth, clampedDay: closingDay)
        let previousMonth = closingMonth.adding(months: -1)
        let previous = LocalDate(yearMonth: previousMonth, clampedDay: closingDay)

        return previous.adding(days: 1)...closing
    }

    func amount(
        paidOn date: LocalDate,
        entries: [Entry]
    ) -> Int {
        guard
            let period = billingPeriod(paidOn: date),
            let card = toWalletId
        else {
            return amount
        }

        let used = entries
            .filter { $0.walletId == card }
            .filter { isBilled($0, paidOn: date, in: period) }
            .reduce(0) { $0 + Self.usage(of: $1) }

        return max(used, 0)
    }

    func billDate(
        for used: LocalDate,
        in month: YearMonth
    ) -> LocalDate? {
        billDates(for: used, count: Self.billChoiceCount).first { occurrenceMonth(of: $0) == month }
    }

    func billDates(
        for used: LocalDate,
        count: Int
    ) -> [LocalDate] {
        guard closingDay != nil else {
            return []
        }

        var schedule = self
        var dates: [LocalDate] = []
        var cursor = used

        schedule.startDate = min(startDate, used)

        while dates.count < count,
              let next = schedule.nextDate(onOrAfter: cursor) {
            let closing = billingPeriod(paidOn: next)?.upperBound ?? next

            if !dates.isEmpty || used <= closing {
                dates.append(next)
            }

            cursor = next.adding(days: 1)
        }

        return dates
    }
}

private extension Recurring {
    static func usage(of entry: Entry) -> Int {
        switch entry.type {
        case .expense: entry.amount
        case .income: -entry.amount
        case .transfer: 0
        }
    }

    func isBilled(
        _ entry: Entry,
        paidOn date: LocalDate,
        in period: ClosedRange<LocalDate>
    ) -> Bool {
        guard let month = entry.billMonth else {
            return period.contains(entry.date)
        }

        return month == occurrenceMonth(of: date)
    }
}
