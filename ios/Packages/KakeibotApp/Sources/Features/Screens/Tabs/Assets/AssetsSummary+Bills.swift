import Core
import Store

extension AssetsSummary.Input {
    var billPages: [BillPage] {
        let bills = list?.upcomingCardBills(
            recurrings: recurrings,
            after: today,
            count: BillPage.limit
        )

        return BillPage.pages(of: bills ?? [])
    }

    func upcomingBills(in pages: [BillPage]) -> [AssetsModel.UpcomingBill] {
        guard let list else {
            return []
        }

        return pages.flatMap(\.bills).map { bill in
            let card = bill.recurring.toWalletId
            let month = bill.month

            let moved = entries(of: card)
                .filter { $0.walletId == card && $0.billMonth != nil }
                .sorted { $0.date < $1.date }

            let movedIn = moved
                .filter { $0.billMonth == month }
                .map { EntryRowItem.dated($0, in: list) }

            let movedOut = moved
                .filter { entry in
                    entry.billMonth != month
                        && bill.period?.contains(entry.date) == true
                }
                .map { EntryRowItem.dated($0, in: list) }

            return AssetsModel.UpcomingBill(
                bill: bill,
                title: list.title(of: bill.recurring) ?? Self.billTitle,
                icon: list.icon(of: bill.recurring),
                source: list.wallets[bill.recurring.walletId]?.name,
                movedIn: movedIn,
                movedOut: movedOut
            )
        }
    }

    func unpaid(of bills: [CardBill]) -> AssetsModel.Unpaid? {
        guard
            let last = bills.last,
            let card = last.recurring.toWalletId,
            let period = last.period
        else {
            return nil
        }

        let cardEntries = entries(of: card)

        let billed = bills.compactMap { bill in
            bill.recurring.billedEntries(paidOn: bill.date, entries: cardEntries).map { (bill, $0) }
        }

        guard billed.count == bills.count else {
            return nil
        }

        var billedIds: Set<Entry.ID> = []

        let groups = billed.map { bill, billedEntries in
            let recorded = billedEntries.filter { $0.date <= today && !billedIds.contains($0.id) }

            billedIds.formUnion(billedEntries.map(\.id))

            return AssetsModel.UnpaidBill(
                bill: bill,
                total: recorded.billedTotal,
                rows: entryRows(of: recorded)
            )
        }

        let later = cardEntries
            .filter { $0.walletId == card && $0.date <= today }
            .filter { !billedIds.contains($0.id) }
            .filter { entry in
                entry.billMonth.map { $0 > last.month } ?? (entry.date > period.upperBound)
            }

        let total = groups.reduce(later.billedTotal) { $0 + $1.total }

        let unpaid = AssetsModel.Unpaid(
            total: total,
            bills: groups,
            later: entryRows(of: later)
        )

        return unpaid.count > 0 ? unpaid : nil
    }
}

private extension AssetsSummary.Input {
    static let billTitle = "引き落とし"
}
