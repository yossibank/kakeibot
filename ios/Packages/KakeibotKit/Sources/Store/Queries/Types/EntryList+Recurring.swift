import Core

public extension EntryList {
    func title(of recurring: Recurring) -> String? {
        let category = recurring.categoryId.flatMap { categories[$0] }
        return recurring.title(categoryName: category?.name)
    }

    func place(of recurring: Recurring) -> String? {
        let wallet = wallets[recurring.walletId]

        guard recurring.type == .transfer else {
            return wallet?.name
        }

        let destination = recurring.toWalletId.flatMap { wallets[$0] }

        return [wallet?.name, destination?.name].compactMap(\.self).joined(separator: " → ")
    }

    func amount(
        of recurring: Recurring,
        on date: LocalDate
    ) -> Int {
        recurring.amount(paidOn: date, entries: entries)
    }

    func upcomingCardBills(
        recurrings: [Recurring],
        after date: LocalDate,
        count: Int = 1
    ) -> [CardBill] {
        CardBill.upcoming(
            recurrings: recurrings,
            wallets: Array(wallets.values),
            entries: entries,
            valuations: valuations,
            adjustments: adjustments,
            after: date,
            count: count
        )
    }

    func icon(of recurring: Recurring) -> Icon? {
        let category = recurring.categoryId.flatMap { categories[$0] }

        let iconId = recurring.type == .transfer
            ? wallets[recurring.walletId]?.iconId
            : category?.iconId

        return iconId.flatMap { icons[$0] }
    }
}
