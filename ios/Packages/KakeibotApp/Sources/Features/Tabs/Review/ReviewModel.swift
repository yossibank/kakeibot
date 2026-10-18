import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReviewModel {
    public var today: LocalDate

    public private(set) var scale: ReviewPeriod.Scale = .month
    public private(set) var kind: ReviewKind = .expense
    public private(set) var offset = 0
    public private(set) var isMovingForward = true
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var list: EntryList?
    public private(set) var budgets: [Budget] = []
    public private(set) var errorMessage: String?

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
        ReviewSummary(entries: entries, in: period.range)
    }

    var previousSummary: ReviewSummary {
        ReviewSummary(entries: entries, in: period.previous.range)
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

    func total(of kind: ReviewKind) -> Int {
        total(of: kind, in: summary)
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

    func change(of kind: ReviewKind) -> Int {
        total(of: kind) - total(of: kind, in: previousSummary)
    }

    func rows(for share: Share) -> [EntryRowItem] {
        guard let list, let type = entryType else {
            return []
        }

        return entries
            .filter { entry in
                let category = entry.categoryId.map(AnyHashable.init)
                let wallet = AnyHashable(entry.walletId)

                return entry.type == type
                    && period.range.contains(entry.date)
                    && (category == share.id || wallet == share.id)
            }
            .sorted { $0.date > $1.date }
            .map { entry in
                let label = "\(entry.date.month)/\(entry.date.day)"
                return EntryRowItem(entry, in: list, dayLabel: label)
            }
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
            errorMessage = Self.loadFailedMessage
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
            errorMessage = Self.saveFailedMessage
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
    struct Ranked {
        let share: Share
        let sortOrder: Int
    }

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
        do {
            for try await list in database.entryListUpdates() {
                self.list = list
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeBudgets() async {
        do {
            for try await budgets in database.budgetUpdates() {
                self.budgets = budgets
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.settingUpdates(.monthStartDay) {
                monthStartDay = startDay
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeWeekStart() async {
        do {
            for try await weekStart in database.settingUpdates(.weekStart) {
                self.weekStart = weekStart
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}
