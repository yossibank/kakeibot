import Core
import DesignSystem
import Foundation
import Store

private extension ReviewModel {
    struct Ranked {
        let share: Share
        let sortOrder: Int
    }
}

private extension ReviewModel {
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
}

public extension ReviewModel.Output {
    var budgetUsage: BudgetUsage? {
        usage(for: nil, spent: summary.expense.total)
    }

    var categoryShares: [ReviewModel.Share] {
        guard
            let breakdown,
            let list = input.list
        else {
            return []
        }

        let ranked = breakdown.byCategory.compactMap { id, amount in
            list.categories[id].map { category in
                let share = ReviewModel.Share(
                    id: category.id,
                    name: category.name,
                    icon: list.icons[category.iconId],
                    amount: amount,
                    ratio: ratio(of: amount, in: breakdown.total),
                    usage: usage(for: category.id, spent: amount)
                )

                return ReviewModel.Ranked(share: share, sortOrder: category.sortOrder)
            }
        }

        return ReviewModel.sorted(ranked)
    }

    var walletShares: [ReviewModel.Share] {
        guard
            let breakdown,
            let list = input.list
        else {
            return []
        }

        let ranked = breakdown.byWallet.compactMap { id, amount in
            list.wallets[id].map { wallet in
                let share = ReviewModel.Share(
                    id: wallet.id,
                    name: wallet.name,
                    icon: list.icons[wallet.iconId],
                    amount: amount,
                    ratio: ratio(of: amount, in: breakdown.total),
                    usage: nil
                )

                return ReviewModel.Ranked(share: share, sortOrder: wallet.sortOrder)
            }
        }

        return ReviewModel.sorted(ranked)
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

    var upcomingRecurringTotal: Int? {
        guard
            entryType != nil,
            period.range.contains(state.today)
        else {
            return nil
        }

        let range = period.range

        let total = upcomingTotals.value(for: range) {
            let type = entryType

            let all = PeriodRecurring.all(
                of: input.recurrings,
                in: range,
                entries: entries,
                today: state.today
            )

            return all
                .filter { $0.status == .upcoming && $0.recurring.type == type }
                .reduce(0) { $0 + $1.amount }
        }

        return total > 0 ? total : nil
    }

    var recurringShare: ReviewModel.Share? {
        guard let recurringTotal else {
            return nil
        }

        let total = max(total(of: input.kind), 1)

        return ReviewModel.Share(
            id: ReviewModel.recurringShareId,
            name: "固定費",
            icon: nil,
            amount: recurringTotal,
            ratio: Double(recurringTotal) / Double(total),
            usage: nil
        )
    }
}

extension ReviewModel.Output {
    func carryover(into month: YearMonth) -> Int {
        input.list?.budgetCarryover(
            budgets: input.budgets,
            from: input.carryoverFrom,
            into: month,
            startingOn: input.monthStartDay
        ) ?? 0
    }
}

private extension ReviewModel.Output {
    var breakdown: ReviewSummary.Breakdown? {
        switch input.kind {
        case .expense: summary.expense
        case .income: summary.income
        case .balance: nil
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
        guard
            input.scale == .month,
            input.kind == .expense
        else {
            return nil
        }

        let month = period.range.upperBound.yearMonth

        guard let budget = input.budgets.amount(for: categoryId, in: month) else {
            return nil
        }

        let carried = categoryId == nil ? carryover(into: month) : 0

        return BudgetUsage(
            budget: budget,
            carryover: carried,
            spent: spent,
            today: state.today,
            periodEnd: period.range.upperBound
        )
    }
}
