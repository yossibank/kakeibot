public extension Recurring {
    func billingPeriod(paidOn date: LocalDate) -> ClosedRange<LocalDate>? {
        guard let closingDay else {
            return nil
        }

        let thisMonth = LocalDate(
            yearMonth: date.yearMonth,
            clampedDay: closingDay
        )

        let latest = thisMonth < date ? 0 : -1
        let months = latest - (paysAfterClosings - 1)

        let closing = LocalDate(
            yearMonth: date.yearMonth.adding(months: months),
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
            .filter { $0.walletId == card && period.contains($0.date) }
            .reduce(0) { $0 + Self.usage(of: $1) }

        return max(used, 0)
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
}
