import Core
import Store

public extension AssetsModel {
    struct OutlookItem: Equatable, Identifiable {
        public let source: Source
        public let date: LocalDate
        public let title: String
        public let wallet: String?
        public let change: Int
        public let balance: Int

        public var id: Source {
            source
        }
    }

    struct Outlook: Equatable {
        public let end: LocalDate
        public let start: Int
        public let items: [OutlookItem]
        public let later: [Plan]
    }
}

public extension AssetsModel.OutlookItem {
    enum Source: Hashable {
        case plan(Entry.ID)
        case recurring(Recurring.ID, LocalDate)
    }

    var isRecurring: Bool {
        switch source {
        case .plan: false
        case .recurring: true
        }
    }
}

public extension AssetsModel.Outlook {
    var isShown: Bool {
        !items.isEmpty || !later.isEmpty
    }

    var total: Int {
        items.last?.balance ?? start
    }

    var incomes: [AssetsModel.OutlookItem] {
        items.filter { $0.change > 0 }
    }

    var recurringExpenses: [AssetsModel.OutlookItem] {
        items.filter { $0.change < 0 && $0.isRecurring }
    }

    var planExpenses: [AssetsModel.OutlookItem] {
        items.filter { $0.change < 0 && !$0.isRecurring }
    }

    var laterChange: Int {
        later.reduce(0) { $0 + $1.change }
    }

    var lowest: AssetsModel.OutlookItem? {
        guard let lowest = items.min(by: { $0.balance < $1.balance }) else {
            return nil
        }

        let isDip = lowest.balance < start && lowest.balance < total
        let isShort = lowest.balance < 0

        guard isDip || isShort else {
            return nil
        }

        return lowest
    }
}

extension AssetsModel {
    func makeOutlook(
        in wallets: [Wallet],
        recurrings: [Recurring],
        monthStartDay: MonthStartDay
    ) -> Outlook {
        let month = today.periodMonth(startingOn: monthStartDay)
        let period = month.period(startingOn: monthStartDay)
        let end = period.upperBound
        let inPeriod = plans.filter { $0.date <= end }

        let planned = inPeriod.map { plan in
            Draft(
                source: .plan(plan.id),
                date: plan.date,
                title: plan.title,
                wallet: plan.wallet,
                change: plan.change
            )
        }

        let upcoming = recurringDrafts(
            of: recurrings,
            in: period,
            wallets: wallets
        )

        let drafts = (planned + upcoming).sorted { $0.date < $1.date }
        var balance = total

        let items = drafts.map { draft in
            balance += draft.change

            return OutlookItem(
                source: draft.source,
                date: draft.date,
                title: draft.title,
                wallet: draft.wallet,
                change: draft.change,
                balance: balance
            )
        }

        return Outlook(
            end: end,
            start: total,
            items: items,
            later: plans.filter { $0.date > end }
        )
    }
}

private extension AssetsModel {
    struct Draft {
        let source: OutlookItem.Source
        let date: LocalDate
        let title: String
        let wallet: String?
        let change: Int
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
        of recurrings: [Recurring],
        in period: ClosedRange<LocalDate>,
        wallets: [Wallet]
    ) -> [Draft] {
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

                return Draft(
                    source: .recurring(item.recurring.id, item.date),
                    date: item.date,
                    title: list.title(of: item.recurring) ?? "固定費",
                    wallet: list.place(of: item.recurring),
                    change: change
                )
            }
    }
}
