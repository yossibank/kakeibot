import Core
import Store

extension AssetsSummary.Input {
    func plans(in wallets: [Wallet]) -> [AssetsModel.Plan] {
        guard let list else {
            return []
        }

        return list.entries
            .filter { $0.date > today }
            .sorted { $0.date < $1.date }
            .compactMap { entry in
                let change = entry.availableChange(in: wallets)

                guard change != 0 else {
                    return nil
                }

                return AssetsModel.Plan(
                    id: entry.id,
                    date: entry.date,
                    title: list.title(of: entry),
                    wallet: Self.walletText(of: entry, in: list),
                    change: change
                )
            }
    }

    func outlook(
        in wallets: [Wallet],
        plans: [AssetsModel.Plan],
        start: Int
    ) -> AssetsModel.Outlook {
        let period = currentMonth.period(startingOn: monthStartDay)
        let end = period.upperBound
        let inPeriod = plans.filter { $0.date <= end }

        let planned = inPeriod.map { plan in
            OutlookDraft(
                source: .plan(plan.id),
                date: plan.date,
                title: plan.title,
                wallet: plan.wallet,
                change: plan.change
            )
        }

        let upcoming = recurringDrafts(in: period, wallets: wallets)
        let drafts = (planned + upcoming).sorted { $0.date < $1.date }
        var balance = start

        let items = drafts.map { draft in
            balance += draft.change

            return AssetsModel.OutlookItem(
                source: draft.source,
                date: draft.date,
                title: draft.title,
                wallet: draft.wallet,
                change: draft.change,
                balance: balance
            )
        }

        return AssetsModel.Outlook(
            end: end,
            start: start,
            items: items,
            later: plans.filter { $0.date > end }
        )
    }
}

private extension AssetsSummary.Input {
    static func walletText(
        of entry: Entry,
        in list: EntryList
    ) -> String? {
        let source = list.wallets[entry.walletId]?.name

        guard
            let source,
            let destination = entry.toWalletId.flatMap({ list.wallets[$0]?.name })
        else {
            return source
        }

        return "\(source) → \(destination)"
    }

    static func change(
        of item: PeriodRecurring,
        in wallets: [Wallet]
    ) -> Int {
        let recurring = item.recurring

        let ids = wallets
            .filter { [.onHand, .card].contains($0.kind.role) }
            .map(\.id)

        let isFromAvailable = ids.contains(recurring.walletId)
        let isToAvailable = recurring.toWalletId.map(ids.contains) ?? false
        let outgoing = isFromAvailable ? -item.amount : 0
        let incoming = isToAvailable ? item.amount : 0
        let fee = isFromAvailable ? recurring.fee ?? 0 : 0

        switch recurring.type {
        case .expense: return outgoing
        case .income: return -outgoing
        case .transfer: return outgoing + incoming - fee
        }
    }

    func recurringDrafts(
        in period: ClosedRange<LocalDate>,
        wallets: [Wallet]
    ) -> [OutlookDraft] {
        guard let list else {
            return []
        }

        let all = PeriodRecurring.all(
            of: recurrings,
            in: period,
            entries: list.entries,
            today: today
        )

        return all
            .filter { $0.status == .upcoming }
            .compactMap { item in
                let change = Self.change(of: item, in: wallets)

                guard change != 0 else {
                    return nil
                }

                return OutlookDraft(
                    source: .recurring(item.recurring.id, item.date),
                    date: item.date,
                    title: list.title(of: item.recurring) ?? "固定費",
                    wallet: list.place(of: item.recurring),
                    change: change
                )
            }
    }
}

private struct OutlookDraft {
    let source: AssetsModel.OutlookItem.Source
    let date: LocalDate
    let title: String
    let wallet: String?
    let change: Int
}
