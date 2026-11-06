import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel: ScreenModel {
    public var today: LocalDate {
        didSet {
            update()
        }
    }

    public private(set) var isListFailed = false
    public private(set) var rewardBank: RewardBank?
    public private(set) var holdings: Holdings
    public private(set) var changeFromLastMonth = 0
    public private(set) var rows: [WalletRow] = []
    public private(set) var upcomingBills: [UpcomingBill] = []
    public private(set) var monthTotals: [MonthTotal] = []

    public private(set) var monthStartDay: MonthStartDay = .first {
        didSet {
            update()
        }
    }

    public private(set) var list: EntryList? {
        didSet {
            update()
        }
    }

    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase

    private var entries: [Entry] = []
    private var entriesByWallet: [Wallet.ID: [Entry]] = [:]

    private var recurrings: [Recurring] = [] {
        didSet {
            update()
        }
    }

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today

        self.holdings = Holdings(
            onHand: 0,
            cards: 0,
            investments: 0,
            loans: 0
        )

        update()
    }
}

public extension AssetsModel {
    static let monthCount = 6

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var total: Int {
        holdings.available
    }

    var showsNetWorth: Bool {
        wallets.contains { [.investment, .loan].contains($0.kind.role) }
    }

    var sections: [WalletSection] {
        let rows = rows

        return Wallet.Kind.Role.allCases.compactMap { role in
            let members = rows.filter { $0.wallet.kind.role == role }

            return members.isEmpty ? nil : WalletSection(role: role, rows: members)
        }
    }

    var upcomingBillTotal: Int {
        upcomingBills.reduce(0) { $0 + $1.bill.amount }
    }

    func adjustModel(for row: WalletRow) -> AssetsAdjustModel {
        AssetsAdjustModel(
            database: database,
            wallet: row.wallet,
            balance: row.balance,
            today: today
        )
    }

    func run() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }

            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeRewardBank()
            }
        }
    }

    func load() async {
        do {
            list = try await database.entryList()
            recurrings = try await database.recurrings()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }
}

private extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"
    static let billTitle = "引き落とし"

    var wallets: [Wallet] {
        let wallets = list.map { Array($0.wallets.values) } ?? []

        return wallets
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var valuations: [Valuation] {
        list?.valuations ?? []
    }

    var adjustments: [Adjustment] {
        list?.adjustments ?? []
    }

    static func rows(
        of entries: [Entry],
        in list: EntryList
    ) -> [EntryRowItem] {
        entries
            .sorted { $0.date < $1.date }
            .map { EntryRowItem.dated($0, in: list) }
    }

    func update() {
        entries = list?.entries ?? []
        entriesByWallet = list?.entriesByWallet ?? [:]
        holdings = makeHoldings()
        changeFromLastMonth = makeChangeFromLastMonth()
        upcomingBills = makeUpcomingBills()
        rows = makeRows()
        monthTotals = makeMonthTotals()
    }

    func makeHoldings() -> Holdings {
        Holdings(
            wallets: wallets,
            entriesByWallet: entriesByWallet,
            valuations: valuations,
            adjustments: adjustments,
            through: today
        )
    }

    func makeChangeFromLastMonth() -> Int {
        let lastMonth = currentMonth.adding(months: -1)
        let end = lastMonth.period(startingOn: monthStartDay).upperBound

        let previous = Holdings(
            wallets: wallets,
            entriesByWallet: entriesByWallet,
            valuations: valuations,
            adjustments: adjustments,
            through: end
        )

        return total - previous.available
    }

    func makeUpcomingBills() -> [UpcomingBill] {
        guard let list else {
            return []
        }

        let bills = list.upcomingCardBills(recurrings: recurrings, after: today)

        return bills.map { bill in
            let card = bill.recurring.toWalletId
            let month = bill.recurring.occurrenceMonth(of: bill.date)

            let moved = entries
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

            return UpcomingBill(
                bill: bill,
                title: list.title(of: bill.recurring) ?? Self.billTitle,
                icon: list.icon(of: bill.recurring),
                source: list.wallets[bill.recurring.walletId]?.name,
                movedIn: movedIn,
                movedOut: movedOut
            )
        }
    }

    func makeRows() -> [WalletRow] {
        let bills = upcomingBills

        return wallets.map { wallet in
            let next = bills.first { $0.bill.recurring.toWalletId == wallet.id }
            let balance = balance(of: wallet)
            let ratio = repaidRatio(of: wallet, balance: balance)

            return WalletRow(
                wallet: wallet,
                icon: list?.icons[wallet.iconId],
                balance: balance,
                nextBill: next?.bill,
                unpaid: next.flatMap { unpaid(of: $0.bill) },
                repayment: repayment(of: wallet),
                repaidRatio: ratio
            )
        }
    }

    func unpaid(of bill: CardBill) -> Unpaid? {
        let recurring = bill.recurring

        guard
            let list,
            let card = recurring.toWalletId,
            let period = bill.period,
            let billedAll = recurring.billedEntries(paidOn: bill.date, entries: entries)
        else {
            return nil
        }

        let month = recurring.occurrenceMonth(of: bill.date)
        let billed = billedAll.filter { $0.date <= today }
        let billedIds = Set(billedAll.map(\.id))

        let later = entries
            .filter { $0.walletId == card && $0.date <= today }
            .filter { !billedIds.contains($0.id) }
            .filter { entry in
                entry.billMonth.map { $0 > month } ?? (entry.date > period.upperBound)
            }

        let total = (billed + later).billedTotal

        let unpaid = Unpaid(
            total: total,
            billed: Self.rows(of: billed, in: list),
            later: Self.rows(of: later, in: list)
        )

        return unpaid.count > 0 ? unpaid : nil
    }

    func makeMonthTotals() -> [MonthTotal] {
        (0..<Self.monthCount).reversed().map { offset in
            let month = currentMonth.adding(months: -offset)
            let period = month.period(startingOn: monthStartDay)
            let end = offset == 0 ? today : period.upperBound

            let holdings = Holdings(
                wallets: wallets,
                entriesByWallet: entriesByWallet,
                valuations: valuations,
                adjustments: adjustments,
                through: end
            )

            return MonthTotal(
                month: month,
                total: holdings.available,
                netWorth: holdings.netWorth
            )
        }
    }

    func balance(of wallet: Wallet) -> Int {
        wallet.balance(
            with: entriesByWallet[wallet.id] ?? [],
            valuations: valuations,
            adjustments: adjustments,
            through: today
        )
    }

    func repaidRatio(
        of wallet: Wallet,
        balance: Int
    ) -> Double? {
        guard
            wallet.kind == .loan,
            let loanAmount = wallet.loanAmount,
            loanAmount > 0
        else {
            return nil
        }

        let repaid = Wallet.repaid(borrowed: loanAmount, balance: balance)

        return Double(repaid) / Double(loanAmount)
    }

    func repayment(of wallet: Wallet) -> Repayment? {
        guard wallet.kind == .loan else {
            return nil
        }

        let balance = balance(of: wallet)

        let repayments = recurrings.filter { recurring in
            recurring.type == .transfer && recurring.toWalletId == wallet.id
        }

        if balance >= 0 {
            return .finished
        }

        if repayments.isEmpty {
            return .unset
        }

        let payoff = LoanPayoff(
            balance: balance,
            repayments: repayments,
            after: today
        )

        return payoff.map(Repayment.until) ?? .open
    }

    func observe() async {
        isListFailed = false

        isListFailed = await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func observeRewardBank() async {
        await observe(
            database.rewardBankUpdates(),
            failure: Self.loadFailedMessage
        ) { bank in
            rewardBank = bank
        }
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(),
            failure: Self.loadFailedMessage
        ) { recurrings in
            self.recurrings = recurrings
        }
    }

    func observeMonthStartDay() async {
        await observe(
            database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            monthStartDay = startDay
        }
    }
}
