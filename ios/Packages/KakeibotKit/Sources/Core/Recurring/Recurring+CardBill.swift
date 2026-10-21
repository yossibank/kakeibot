public extension Recurring {
    func billingPeriod(paidOn date: LocalDate) -> ClosedRange<LocalDate>? {
        guard let closingDay else {
            return nil
        }

        let thisMonth = LocalDate(
            yearMonth: date.yearMonth,
            clampedDay: closingDay
        )

        let closing = thisMonth < date
            ? thisMonth
            : LocalDate(
                yearMonth: date.yearMonth.adding(months: -1),
                clampedDay: closingDay
            )

        let previous = LocalDate(
            yearMonth: closing.yearMonth.adding(months: -1),
            clampedDay: closingDay
        )

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
            .filter { Self.isBilled($0, paidOn: date, in: period) }
            .reduce(0) { $0 + Self.usage(of: $1) }

        return max(used, 0)
    }

    func billDates(
        for used: LocalDate,
        count: Int
    ) -> [LocalDate] {
        guard closingDay != nil else {
            return []
        }

        var dates: [LocalDate] = []
        var cursor = used

        while dates.count < count,
              let next = nextDate(onOrAfter: cursor) {
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
    static func isBilled(
        _ entry: Entry,
        paidOn date: LocalDate,
        in period: ClosedRange<LocalDate>
    ) -> Bool {
        guard let month = entry.billMonth else {
            return period.contains(entry.date)
        }

        return month == date.yearMonth
    }

    static func usage(of entry: Entry) -> Int {
        switch entry.type {
        case .expense: entry.amount
        case .income: -entry.amount
        case .transfer: 0
        }
    }
}
