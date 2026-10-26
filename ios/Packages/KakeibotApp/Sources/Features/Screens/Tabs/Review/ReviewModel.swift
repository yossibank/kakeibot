import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReviewModel: ScreenModel {
    public var today: LocalDate

    public private(set) var scale: ReviewPeriod.Scale = .month
    public private(set) var kind: ReviewKind = .expense
    public private(set) var offset = 0
    public private(set) var isMovingForward = true
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var list: EntryList?
    public private(set) var budgets: [Budget] = []
    public private(set) var stampCalendar: StampCalendar?

    public internal(set) var errorNotice = ErrorNotice()

    private var recurrings: [Recurring] = []

    @ObservationIgnored private var summaries: [
        ClosedRange<LocalDate>: ReviewSummary
    ] = [:]

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension ReviewModel {
    struct Share: Identifiable {
        public let id: AnyHashable
        public let name: String
        public let icon: Icon?
        public let amount: Int
        public let ratio: Double
        public let usage: BudgetUsage?
    }

    struct Move: Identifiable {
        public let wallet: Wallet
        public let icon: Icon?
        public let amount: Int
        public let balance: Int
        public let payoff: LoanPayoff?

        public var id: Wallet.ID {
            wallet.id
        }
    }

    static let recurringShareId = AnyHashable("recurring")

    var period: ReviewPeriod {
        let current = ReviewPeriod(
            scale: scale,
            containing: today,
            monthStartDay: monthStartDay,
            weekStart: weekStart
        )

        return current.adding(offset)
    }

    var canMoveForward: Bool {
        offset < 0
    }

    var summary: ReviewSummary {
        summary(in: period.range)
    }

    var previousSummary: ReviewSummary {
        summary(in: period.previous.range)
    }

    var total: Int {
        total(of: kind)
    }

    var change: Int {
        change(of: kind)
    }

    var budgetUsage: BudgetUsage? {
        usage(for: nil, spent: summary.expense.total)
    }

    var categoryShares: [Share] {
        guard let breakdown, let list else {
            return []
        }

        let ranked = breakdown.byCategory.compactMap { id, amount in
            list.categories[id].map { category in
                let share = Share(
                    id: category.id,
                    name: category.name,
                    icon: list.icons[category.iconId],
                    amount: amount,
                    ratio: ratio(of: amount, in: breakdown.total),
                    usage: usage(for: category.id, spent: amount)
                )

                return Ranked(share: share, sortOrder: category.sortOrder)
            }
        }

        return Self.sorted(ranked)
    }

    var walletShares: [Share] {
        guard let breakdown, let list else {
            return []
        }

        let ranked = breakdown.byWallet.compactMap { id, amount in
            list.wallets[id].map { wallet in
                let share = Share(
                    id: wallet.id,
                    name: wallet.name,
                    icon: list.icons[wallet.iconId],
                    amount: amount,
                    ratio: ratio(of: amount, in: breakdown.total),
                    usage: nil
                )

                return Ranked(share: share, sortOrder: wallet.sortOrder)
            }
        }

        return Self.sorted(ranked)
    }

    var recurringTotal: Int? {
        guard let type = entryType else {
            return nil
        }

        let total = entries
            .filter { entry in
                entry.type == type
                    && entry.recurringId != nil
                    && period.range.contains(entry.date)
            }
            .reduce(0) { $0 + $1.amount }

        return total > 0 ? total : nil
    }

    var recurringShare: Share? {
        guard let recurringTotal else {
            return nil
        }

        let total = max(total(of: kind), 1)

        return Share(
            id: Self.recurringShareId,
            name: "固定費",
            icon: nil,
            amount: recurringTotal,
            ratio: Double(recurringTotal) / Double(total),
            usage: nil
        )
    }

    var moves: [Move] {
        guard let list else {
            return []
        }

        return list.wallets.values
            .filter { Self.moveRoles.contains($0.kind.role) && $0.archivedAt == nil }
            .sorted { lhs, rhs in
                let lhsOrder = Self.moveRoles.firstIndex(of: lhs.kind.role) ?? 0
                let rhsOrder = Self.moveRoles.firstIndex(of: rhs.kind.role) ?? 0

                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }

                return lhs.sortOrder < rhs.sortOrder
            }
            .compactMap { wallet in
                let amount = moveEntries(to: wallet, in: list).reduce(0) { $0 + $1.amount }

                guard amount > 0 else {
                    return nil
                }

                let balance = wallet.balance(with: entries, valuations: list.valuations)

                return Move(
                    wallet: wallet,
                    icon: list.icons[wallet.iconId],
                    amount: amount,
                    balance: balance,
                    payoff: payoff(of: wallet, balance: balance)
                )
            }
    }

    var stampTallies: [StampCalendar.Tally] {
        stampCalendar?.tallies(in: period.range) ?? []
    }

    func repaymentRatio(in moves: [Move]) -> Double {
        let total = moves.reduce(0) { $0 + $1.amount }

        let repaid = moves
            .filter { $0.wallet.kind.role == .loan }
            .reduce(0) { $0 + $1.amount }

        return total == 0 ? 0 : Double(repaid) / Double(total)
    }

    func share(of move: Move) -> Share {
        Share(
            id: AnyHashable(MoveKey(walletId: move.wallet.id)),
            name: move.wallet.name,
            icon: move.icon,
            amount: move.amount,
            ratio: 0,
            usage: nil
        )
    }

    func total(of kind: ReviewKind) -> Int {
        total(of: kind, in: summary)
    }

    func recurringId(of id: Entry.ID) -> Recurring.ID? {
        entries.first { $0.id == id }?.recurringId
    }

    func change(of kind: ReviewKind) -> Int {
        total(of: kind) - total(of: kind, in: previousSummary)
    }

    func rows(for share: Share) -> [EntryRowItem] {
        if let key = share.id.base as? MoveKey {
            return moveRows(to: key.walletId)
        }

        guard let list, let type = entryType else {
            return []
        }

        return entries
            .filter { entry in
                let category = entry.categoryId.map(AnyHashable.init)
                let wallet = AnyHashable(entry.walletId)

                let isRecurring = share.id == Self.recurringShareId
                    && entry.recurringId != nil

                return entry.type == type
                    && period.range.contains(entry.date)
                    && (
                        category == share.id
                            || wallet == share.id
                            || isRecurring
                    )
            }
            .sorted { $0.date > $1.date }
            .map { entry in
                let label = "\(entry.date.month)/\(entry.date.day)"

                return EntryRowItem(entry, in: list, dayLabel: label)
            }
    }

    func stampDays(of tally: StampCalendar.Tally) -> [LocalDate] {
        let stamps = stampCalendar.map { Array($0.stamps.values) } ?? []

        return stamps
            .filter { $0.iconId == tally.icon.id }
            .map(\.date)
            .filter { period.range.contains($0) }
            .sorted(by: >)
    }

    func day(on date: LocalDate) -> EntryDay? {
        list?.days.first { $0.date == date }
    }

    func run() async {
        await loadSelection()

        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeBudgets()
            }

            group.addTask {
                await self.observeStamps()
            }

            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }

            group.addTask {
                await self.observeWeekStart()
            }
        }
    }

    func loadSelection() async {
        do {
            scale = try await database.setting(.reviewScale)
            kind = try await database.setting(.reviewKind)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setScale(_ scale: ReviewPeriod.Scale) {
        let scales = ReviewPeriod.Scale.allCases
        let from = scales.firstIndex(of: self.scale) ?? 0
        let to = scales.firstIndex(of: scale) ?? 0

        isMovingForward = to > from
        self.scale = scale
        offset = 0
    }

    func setKind(_ kind: ReviewKind) {
        self.kind = kind
    }

    func saveSelection() async {
        do {
            try await database.setSetting(.reviewScale, to: scale)
            try await database.setSetting(.reviewKind, to: kind)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func canMove(by count: Int) -> Bool {
        offset + count <= 0
    }

    func move(by count: Int) {
        guard canMove(by: count) else {
            return
        }

        isMovingForward = count > 0
        offset += count
    }
}

private extension ReviewModel {
    struct MoveKey: Hashable {
        let walletId: Wallet.ID
    }

    struct Ranked {
        let share: Share
        let sortOrder: Int
    }

    static let moveRoles: [Wallet.Kind.Role] = [.loan, .investment]
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    var entries: [Entry] {
        list?.days.flatMap(\.entries) ?? []
    }

    var entryType: Entry.Kind? {
        switch kind {
        case .expense: .expense
        case .income: .income
        case .balance: nil
        }
    }

    var breakdown: ReviewSummary.Breakdown? {
        switch kind {
        case .expense: summary.expense
        case .income: summary.income
        case .balance: nil
        }
    }

    static func sorted(_ ranked: [Ranked]) -> [Share] {
        ranked
            .sorted { lhs, rhs in
                if lhs.share.amount != rhs.share.amount {
                    return lhs.share.amount > rhs.share.amount
                }

                return lhs.sortOrder < rhs.sortOrder
            }
            .map(\.share)
    }

    func summary(in range: ClosedRange<LocalDate>) -> ReviewSummary {
        if let summary = summaries[range] {
            return summary
        }

        let summary = ReviewSummary(entries: entries, in: range)

        summaries[range] = summary

        return summary
    }

    func total(
        of kind: ReviewKind,
        in summary: ReviewSummary
    ) -> Int {
        switch kind {
        case .expense: summary.expense.total
        case .income: summary.income.total
        case .balance: summary.balance
        }
    }

    func ratio(
        of amount: Int,
        in total: Int
    ) -> Double {
        total > 0 ? Double(amount) / Double(total) : 0
    }

    func usage(
        for categoryId: EntryCategory.ID?,
        spent: Int
    ) -> BudgetUsage? {
        guard scale == .month, kind == .expense else {
            return nil
        }

        let month = period.range.upperBound.yearMonth

        guard let budget = budgets.amount(for: categoryId, in: month) else {
            return nil
        }

        return BudgetUsage(
            budget: budget,
            spent: spent,
            today: today,
            periodEnd: period.range.upperBound
        )
    }

    func observe() async {
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
            summaries = [:]
        }
    }

    func observeStamps() async {
        await observe(
            database.stampCalendarUpdates(),
            failure: Self.loadFailedMessage
        ) { calendar in
            stampCalendar = calendar
        }
    }

    func observeBudgets() async {
        await observe(
            database.budgetUpdates(),
            failure: Self.loadFailedMessage
        ) { budgets in
            self.budgets = budgets
        }
    }

    func moveEntries(
        to wallet: Wallet,
        in list: EntryList
    ) -> [Entry] {
        entries.filter { entry in
            let from = list.wallets[entry.walletId]?.kind.role

            return entry.type == .transfer
                && entry.toWalletId == wallet.id
                && from != wallet.kind.role
                && period.range.contains(entry.date)
        }
    }

    func moveRows(to walletId: Wallet.ID) -> [EntryRowItem] {
        guard let list, let wallet = list.wallets[walletId] else {
            return []
        }

        return moveEntries(to: wallet, in: list)
            .sorted { $0.date > $1.date }
            .map { entry in
                let label = "\(entry.date.month)/\(entry.date.day)"

                return EntryRowItem(entry, in: list, dayLabel: label)
            }
    }

    func payoff(
        of wallet: Wallet,
        balance: Int
    ) -> LoanPayoff? {
        guard
            wallet.kind == .loan,
            balance < 0
        else {
            return nil
        }

        let repayments = recurrings.filter { recurring in
            recurring.type == .transfer && recurring.toWalletId == wallet.id
        }

        return LoanPayoff(
            balance: balance,
            repayments: repayments,
            after: today
        )
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

    func observeWeekStart() async {
        await observe(
            database.settingUpdates(.weekStart),
            failure: Self.loadFailedMessage
        ) { weekStart in
            self.weekStart = weekStart
        }
    }
}
