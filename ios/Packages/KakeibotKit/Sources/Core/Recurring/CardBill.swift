public struct CardBill: Hashable, Sendable {
    public let recurring: Recurring
    public let date: LocalDate
    public let amount: Int
    public let balanceBefore: Int

    public init(
        recurring: Recurring,
        date: LocalDate,
        amount: Int,
        balanceBefore: Int
    ) {
        self.recurring = recurring
        self.date = date
        self.amount = amount
        self.balanceBefore = balanceBefore
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

    static func upcoming(
        recurrings: [Recurring],
        wallets: [Wallet],
        entries: [Entry],
        after today: LocalDate
    ) -> [CardBill] {
        let cards = Set(wallets.filter { $0.kind == .card }.map(\.id))
        let tomorrow = today.adding(days: 1)

        var balances: [Wallet.ID: Int] = [:]

        return recurrings
            .filter { recurring in
                recurring.type == .transfer
                    && recurring.toWalletId.map(cards.contains) == true
            }
            .compactMap { recurring in
                recurring.nextDate(onOrAfter: tomorrow).map { (recurring, $0) }
            }
            .sorted { $0.1 < $1.1 }
            .map { recurring, date in
                let source = recurring.walletId
                let wallet = wallets.first { $0.id == source }
                let current = wallet?.balance(with: entries) ?? 0
                let before = balances[source] ?? current
                let amount = recurring.amount(paidOn: date, entries: entries)

                balances[source] = before - amount

                return CardBill(
                    recurring: recurring,
                    date: date,
                    amount: amount,
                    balanceBefore: before
                )
            }
    }
}
