import Core
import DesignSystem
import Foundation
import Store

public extension ReviewModel {
    var budgetUsage: BudgetUsage? {
        usage(for: nil, spent: summary.expense.total)
    }

    var categoryShares: [Share] {
        guard
            let breakdown,
            let list
        else {
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
        guard
            let breakdown,
            let list
        else {
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
}

private extension ReviewModel {
    struct Ranked {
        let share: Share
        let sortOrder: Int
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
            scale == .month,
            kind == .expense
        else {
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
