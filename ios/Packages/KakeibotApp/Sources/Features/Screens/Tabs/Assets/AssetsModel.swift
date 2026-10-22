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
    public private(set) var rewardBank: RewardBank?

    public internal(set) var errorNotice = ErrorNotice()

    private var recurrings: [Recurring] = []

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension AssetsModel {
    struct WalletRow: Identifiable, Equatable {
        public let wallet: Wallet
        public let icon: Icon?
        public let balance: Int
        public let nextBill: CardBill?
        public let repayment: Repayment?

        public var id: Wallet.ID {
            wallet.id
        }
    }

    enum Repayment: Equatable {
        case unset
        case finished
        case open
        case until(LoanPayoff)
    }

    struct RewardMonth: Identifiable, Equatable {
        public let month: YearMonth
        public let logs: [RewardLog]

        public var id: YearMonth {
            month
        }
    }

    struct WalletSection: Identifiable, Equatable {
        public let role: Wallet.Kind.Role
        public let rows: [WalletRow]

        public var id: Wallet.Kind.Role {
            role
        }
    }

    struct MonthTotal: Identifiable, Equatable {
        public let month: YearMonth
        public let total: Int
        public let netWorth: Int

        public var id: YearMonth {
            month
        }
    }

    struct UpcomingBill: Identifiable, Equatable {
        public let bill: CardBill
        public let title: String
        public let icon: Icon?
        public let source: String?
        public let movedIn: [EntryRowItem]
        public let movedOut: [EntryRowItem]

        public var id: Recurring.ID {
            bill.recurring.id
        }
    }

    static let monthCount = 6

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var holdings: Holdings {
        Holdings(wallets: wallets, entries: entries, valuations: valuations)
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

            return WalletRow(
                wallet: wallet,
                icon: list?.icons[wallet.iconId],
                balance: balance(of: wallet),
                nextBill: next?.bill,
                repayment: repayment(of: wallet)
            )
        }
    }

    var sections: [WalletSection] {
        let rows = rows

        return Wallet.Kind.Role.allCases.compactMap { role in
            let members = rows.filter { $0.wallet.kind.role == role }
            return members.isEmpty
                ? nil
                : WalletSection(role: role, rows: members)
        }
    }

    var upcomingBills: [UpcomingBill] {
        guard let list else {
            return []
        }

        let bills = CardBill.upcoming(
            recurrings: recurrings,
            wallets: Array(list.wallets.values),
            entries: entries,
            after: today
        )

        return bills.map { bill in
            let card = bill.recurring.toWalletId
            let month = bill.date.yearMonth

            let moved = entries
                .filter { $0.walletId == card && $0.billMonth != nil }
                .sorted { $0.date < $1.date }

            let movedIn = moved.filter { $0.billMonth == month }

            let movedOut = moved.filter { entry in
                entry.billMonth != month
                    && bill.period?.contains(entry.date) == true
            }

            return UpcomingBill(
                bill: bill,
                title: list.title(of: bill.recurring) ?? Self.billTitle,
                icon: list.icon(of: bill.recurring),
                source: list.wallets[bill.recurring.walletId]?.name,
                movedIn: movedIn.map { Self.row(of: $0, in: list) },
                movedOut: movedOut.map { Self.row(of: $0, in: list) }
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

    var rewardBalance: Int {
        rewardBank?.balance ?? 0
    }

    var recentRewards: [RewardLog] {
        Array((rewardBank?.logs ?? []).prefix(Self.recentRewardCount))
    }

    var rewardGoal: RewardGoal? {
        rewardBank?.waitingGoals.first
    }

    var waitingGoals: [RewardGoal] {
        rewardBank?.waitingGoals ?? []
    }

    var boughtGoals: [RewardGoal] {
        rewardBank?.boughtGoals ?? []
    }

    var rewardHistory: [RewardMonth] {
        var months: [RewardMonth] = []

        for log in rewardBank?.logs ?? [] {
            let month = log.date.yearMonth

            if let last = months.last, last.month == month {
                months[months.count - 1] = RewardMonth(
                    month: month,
                    logs: last.logs + [log]
                )
            } else {
                months.append(RewardMonth(month: month, logs: [log]))
            }
        }

        return months
    }

    func remaining(to goal: RewardGoal) -> Int {
        rewardBank?.remaining(to: goal) ?? goal.targetAmount
    }

    func progress(to goal: RewardGoal) -> Double {
        rewardBank?.progress(to: goal) ?? 0
    }

    func goalEditModel(editing goal: RewardGoal?) -> AssetsGoalEditModel {
        AssetsGoalEditModel(database: database, editing: goal)
    }

    func setPurchased(
        _ goal: RewardGoal,
        isPurchased: Bool
    ) async {
        do {
            try await database.setRewardGoalPurchased(
                goal.id,
                isPurchased: isPurchased,
                at: Date()
            )
        } catch {
            errorNotice.show(Self.goalFailedMessage)
        }
    }

    func rewardRule(for log: RewardLog) -> RewardRule? {
        rewardBank?.rule(for: log)
    }

    func rewardIcon(for rule: RewardRule) -> Icon? {
        rewardBank?.icon(for: rule)
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
    static let recentRewardCount = 3
    static let goalFailedMessage = "目標を保存できませんでした"
    static let billTitle = "引き落とし"

    static func row(
        of entry: Entry,
        in list: EntryList
    ) -> EntryRowItem {
        let day = "\(entry.date.month)/\(entry.date.day)"
        return EntryRowItem(entry, in: list, dayLabel: day)
    }

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

    func balance(of wallet: Wallet) -> Int {
        wallet.balance(with: entries, valuations: valuations)
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
        await observe(
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
