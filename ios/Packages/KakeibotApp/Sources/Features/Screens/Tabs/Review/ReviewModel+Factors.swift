import Core
import Foundation

extension ReviewModel {
    enum Factor: Hashable {
        case current
        case previous
        case memo(String)
    }

    struct FactorKey: Hashable {
        let categoryId: EntryCategory.ID
        let factor: Factor
    }

    struct MonthAmount: Hashable {
        let month: Int
        let amount: Int
    }

    var breakdownMonths: [MonthAmount] {
        guard
            scale == .year,
            !hasPreviousEntries,
            let id = breakdownCategory
        else {
            return []
        }

        let range = commentRange
        let first = range.lowerBound.yearMonth.month
        let last = range.upperBound.yearMonth.month

        let totals = entries.reduce(into: [Int: Int]()) { totals, entry in
            guard
                entry.type == .expense,
                entry.categoryId == id,
                range.contains(entry.date)
            else {
                return
            }

            totals[entry.date.yearMonth.month, default: 0] += entry.amount
        }

        return (first...max(first, last)).map { month in
            MonthAmount(month: month, amount: totals[month, default: 0])
        }
    }

    var spentCategoryNames: [String] {
        summary.expense.byCategory.keys.compactMap { list?.categories[$0]?.name }
    }

    func factorShare(of factor: Factor) -> Share? {
        breakdownCategory.flatMap { factorShare(of: factor, in: $0) }
    }

    func categoryShare(named name: String) -> Share? {
        let id = summary.expense.byCategory.keys.first { list?.categories[$0]?.name == name }
        return id.flatMap { factorShare(of: .current, in: $0) }
    }

    func factorRows(of key: FactorKey) -> [EntryRowItem] {
        guard let list else {
            return []
        }

        return factorEntries(of: key)
            .sorted { $0.date > $1.date }
            .map { entry in
                EntryRowItem.dated(entry, in: list)
            }
    }
}

private extension ReviewModel {
    func factorShare(
        of factor: Factor,
        in id: EntryCategory.ID
    ) -> Share? {
        guard
            let list,
            let category = list.categories[id]
        else {
            return nil
        }

        let key = FactorKey(categoryId: id, factor: factor)
        let amount = factorEntries(of: key).reduce(0) { $0 + $1.amount }

        let name = switch factor {
        case .current: category.name
        case .previous: "\(category.name)（前の\(scale.unitName)）"
        case let .memo(memo): memo
        }

        return Share(
            id: AnyHashable(key),
            name: name,
            icon: list.icons[category.iconId],
            amount: amount,
            ratio: 0,
            usage: nil
        )
    }

    func factorEntries(of key: FactorKey) -> [Entry] {
        let range = key.factor == .previous ? period.comparisonRange(today: today) : period.range

        return entries.filter { entry in
            let isMemo = switch key.factor {
            case .current, .previous: true
            case let .memo(memo): ReviewBreakdown.normalized(entry.memo) == memo
            }

            return entry.type == .expense
                && range.contains(entry.date)
                && entry.categoryId == key.categoryId
                && isMemo
        }
    }
}
