public struct CardBill: Hashable, Sendable {
    public let recurring: Recurring
    public let date: LocalDate
    public let amount: Int
    public let balanceBefore: Int
    public let isOpen: Bool

    public init(
        recurring: Recurring,
        date: LocalDate,
        amount: Int,
        balanceBefore: Int,
        isOpen: Bool = false
    ) {
        self.recurring = recurring
        self.date = date
        self.amount = amount
        self.balanceBefore = balanceBefore
        self.isOpen = isOpen
    }
}

public extension CardBill {
    var balanceAfter: Int {
        balanceBefore - amount
    }

    var shortage: Int {
        max(-balanceAfter, 0)
    }

    var period: ClosedRange<LocalDate>? {
        recurring.billingPeriod(paidOn: date)
    }

    var month: YearMonth {
        recurring.occurrenceMonth(of: date)
    }

    static func upcoming(
        recurrings: [Recurring],
        wallets: [Wallet],
        entries: [Entry],
        valuations: [Valuation],
        adjustments: [Adjustment],
        after today: LocalDate,
        count: Int = 1
    ) -> [CardBill] {
        let cardIds = wallets.filter { $0.kind == .card }.map(\.id)
        let cards = Set(cardIds)
        let tomorrow = today.adding(days: 1)

        var paid: [Wallet.ID: Int] = [:]

        return recurrings
            .filter { recurring in
                recurring.type == .transfer
                    && recurring.toWalletId.map(cards.contains) == true
            }
            .flatMap { recurring in
                dates(of: recurring, from: tomorrow, count: count).map { (recurring, $0) }
            }
            .sorted { $0.1 < $1.1 }
            .map { recurring, date in
                let source = recurring.walletId
                let wallet = wallets.first { $0.id == source }

                let recorded = wallet?.balance(
                    with: entries,
                    valuations: valuations,
                    adjustments: adjustments,
                    through: date.adding(days: -1)
                ) ?? 0

                let before = recorded - paid[source, default: 0]
                let amount = recurring.amount(paidOn: date, entries: entries)
                let closing = recurring.billingPeriod(paidOn: date)?.upperBound
                let isOpen = closing.map { today <= $0 } ?? false

                paid[source, default: 0] += amount

                return CardBill(
                    recurring: recurring,
                    date: date,
                    amount: amount,
                    balanceBefore: before,
                    isOpen: isOpen
                )
            }
    }
}

private extension CardBill {
    static func dates(
        of recurring: Recurring,
        from start: LocalDate,
        count: Int
    ) -> [LocalDate] {
        var dates: [LocalDate] = []
        var cursor = start

        while dates.count < count,
              let next = recurring.nextDate(onOrAfter: cursor) {
            dates.append(next)
            cursor = next.adding(days: 1)
        }

        return dates
    }
}
