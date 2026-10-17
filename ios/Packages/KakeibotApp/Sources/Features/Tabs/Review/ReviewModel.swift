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
    public private(set) var kind: Kind = .expense
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
    enum Kind: CaseIterable, Hashable, Sendable {
        case expense
        case income
        case balance
    }

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
        total(of: summary)
    }

    var change: Int {
        total - total(of: previousSummary)
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

    func setScale(_ scale: ReviewPeriod.Scale) {
        self.scale = scale
        offset = 0
    }

    func setKind(_ kind: Kind) {
        self.kind = kind
    }

    func move(by count: Int) {
        guard offset + count <= 0 else {
            return
        }

        isMovingForward = count > 0
        offset += count
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
            for try await startDay in database.monthStartDayUpdates() {
                monthStartDay = startDay
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeWeekStart() async {
        do {
            for try await weekStart in database.weekStartUpdates() {
                self.weekStart = weekStart
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension ReviewModel {
    struct Ranked {
        let share: Share
        let sortOrder: Int
    }

    static let loadFailedMessage = "記録を読めませんでした"

    var entries: [Entry] {
        list?.days.flatMap(\.entries) ?? []
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

    func total(of summary: ReviewSummary) -> Int {
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
}
