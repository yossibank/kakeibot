import Core

public extension EntryList {
    func title(of recurring: Recurring) -> String? {
        let memo = recurring.memo.flatMap { $0.isEmpty ? nil : $0 }
        let category = recurring.categoryId.flatMap { categories[$0] }

        return memo ?? category?.name
    }

    func place(of recurring: Recurring) -> String? {
        let wallet = wallets[recurring.walletId]

        guard recurring.type == .transfer else {
            return wallet?.name
        }

        let destination = recurring.toWalletId.flatMap { wallets[$0] }

        return [wallet?.name, destination?.name]
            .compactMap(\.self)
            .joined(separator: " → ")
    }

    func amount(
        of recurring: Recurring,
        on date: LocalDate
    ) -> Int {
        let entries = days.flatMap(\.entries)

        return recurring.amount(paidOn: date, entries: entries)
    }

    func icon(of recurring: Recurring) -> Icon? {
        let category = recurring.categoryId.flatMap { categories[$0] }

        let iconId = recurring.type == .transfer
            ? wallets[recurring.walletId]?.iconId
            : category?.iconId

        return iconId.flatMap { icons[$0] }
    }
}
