import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel: ScreenModel {
    public var today: LocalDate

    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var list: EntryList?
    public private(set) var isListFailed = false
    public private(set) var rewardBank: RewardBank?

    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase

    private var recurrings: [Recurring] = []

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension AssetsModel {
    static let monthCount = 6

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var holdings: Holdings {
        Holdings(
            wallets: wallets,
            entries: entries,
            valuations: valuations,
            through: today
        )
    }

    var total: Int {
        holdings.available
    }

    var showsNetWorth: Bool {
        wallets.contains { [.investment, .loan].contains($0.kind.role) }
    }

    var changeFromLastMonth: Int {
        let lastMonth = currentMonth.adding(months: -1)
        let end = lastMonth.period(startingOn: monthStartDay).upperBound

        let previous = Holdings(
            wallets: wallets,
            entries: entries,
            valuations: valuations,
            through: end
        )

        return total - previous.available
    }

    var rows: [WalletRow] {
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
                repayment: repayment(of: wallet),
                repaidRatio: ratio
            )
        }
    }

    var sections: [WalletSection] {
        let rows = rows

        return Wallet.Kind.Role.allCases.compactMap { role in
            let members = rows.filter { $0.wallet.kind.role == role }

            return members.isEmpty ? nil : WalletSection(role: role, rows: members)
        }
    }

    var upcomingBills: [UpcomingBill] {
        guard let list else {
            return []
        }

        let allWallets = Array(list.wallets.values)

        let bills = CardBill.upcoming(
            recurrings: recurrings,
            wallets: allWallets,
            entries: entries,
            valuations: valuations,
            after: today
        )

        return bills.map { bill in
            let card = bill.recurring.toWalletId
            let month = bill.recurring.occurrenceMonth(of: bill.date)

            let moved = entries
                .filter { $0.walletId == card && $0.billMonth != nil }
                .sorted { $0.date < $1.date }

            let movedIn = moved
                .filter { $0.billMonth == month }
                .map { Self.row(of: $0, in: list) }

            let movedOut = moved
                .filter { entry in
                    entry.billMonth != month
                        && bill.period?.contains(entry.date) == true
                }
                .map { Self.row(of: $0, in: list) }

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

    var upcomingBillTotal: Int {
        upcomingBills.reduce(0) { $0 + $1.bill.amount }
    }

    var monthTotals: [MonthTotal] {
        (0..<Self.monthCount).reversed().map { offset in
            let month = currentMonth.adding(months: -offset)
            let period = month.period(startingOn: monthStartDay)
            let end = offset == 0 ? today : period.upperBound

            let holdings = Holdings(
                wallets: wallets,
                entries: entries,
                valuations: valuations,
                through: end
            )

            return MonthTotal(
                month: month,
                total: holdings.available,
                netWorth: holdings.netWorth
            )
        }
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

    var entries: [Entry] {
        list?.days.flatMap(\.entries) ?? []
    }

    var valuations: [Valuation] {
        list?.valuations ?? []
    }

    static func row(
        of entry: Entry,
        in list: EntryList
    ) -> EntryRowItem {
        let day = "\(entry.date.month)/\(entry.date.day)"
        return EntryRowItem(entry, in: list, dayLabel: day)
    }

    func balance(of wallet: Wallet) -> Int {
        wallet.balance(
            with: entries,
            valuations: valuations,
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

        let repaid = loanAmount - max(-balance, 0)
        let ratio = Double(repaid) / Double(loanAmount)
        let lower = max(ratio, 0)

        return min(lower, 1)
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
