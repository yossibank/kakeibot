import Core
import Store

struct AssetsSummary: Sendable {
    let input: Input
    let wallets: [Wallet]
    let holdings: Holdings
    let changeFromLastMonth: Int
    let monthTotals: [AssetsModel.MonthTotal]
    let billPages: [BillPage]
    let upcomingBills: [AssetsModel.UpcomingBill]
    let rows: [AssetsModel.WalletRow]
    let sections: [AssetsModel.WalletSection]
    let plans: [AssetsModel.Plan]
    let outlook: AssetsModel.Outlook
}

extension AssetsSummary {
    struct Input: Sendable {
        var list: EntryList?
        var recurrings: [Recurring] = []
        var monthStartDay: MonthStartDay = .first
        var today: LocalDate
    }
}

extension AssetsSummary {
    init(_ input: Input) {
        let wallets = input.activeWallets
        let current = input.holdings(of: wallets, through: input.today)
        let previous = input.holdings(of: wallets, through: input.lastMonthEnd)
        let billPages = input.billPages
        let upcomingBills = input.upcomingBills(in: billPages)
        let rows = input.rows(of: wallets, bills: upcomingBills)
        let plans = input.plans(in: wallets)

        let monthTotals = input.monthTotals(
            of: wallets,
            current: current,
            previous: previous
        )

        let outlook = input.outlook(
            in: wallets,
            plans: plans,
            start: current.available
        )

        self.input = input
        self.wallets = wallets
        self.billPages = billPages
        self.upcomingBills = upcomingBills
        self.rows = rows
        self.plans = plans
        self.monthTotals = monthTotals
        self.outlook = outlook
        self.holdings = current
        self.changeFromLastMonth = current.available - previous.available
        self.sections = AssetsModel.WalletSection.sections(of: rows)
    }

    @concurrent
    static func make(_ input: Input) async -> AssetsSummary {
        AssetsSummary(input)
    }
}

extension AssetsSummary.Input {
    static let monthCount = 6

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var lastMonthEnd: LocalDate {
        let lastMonth = currentMonth.adding(months: -1)
        return lastMonth.period(startingOn: monthStartDay).upperBound
    }

    var activeWallets: [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func entries(of walletId: Wallet.ID?) -> [Entry] {
        guard let walletId else {
            return []
        }

        return list?.entriesByWallet[walletId] ?? []
    }

    func holdings(
        of wallets: [Wallet],
        through date: LocalDate
    ) -> Holdings {
        Holdings(
            wallets: wallets,
            entriesByWallet: list?.entriesByWallet ?? [:],
            valuations: list?.valuations ?? [],
            adjustments: list?.adjustments ?? [],
            through: date
        )
    }

    func monthTotals(
        of wallets: [Wallet],
        current: Holdings,
        previous: Holdings
    ) -> [AssetsModel.MonthTotal] {
        (0..<Self.monthCount).reversed().map { offset in
            let month = currentMonth.adding(months: -offset)
            let end = month.period(startingOn: monthStartDay).upperBound

            let holdings = switch offset {
            case 0: current
            case 1: previous
            default: holdings(of: wallets, through: end)
            }

            return AssetsModel.MonthTotal(
                month: month,
                total: holdings.available,
                netWorth: holdings.netWorth
            )
        }
    }
}
