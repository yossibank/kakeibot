import Core
import Foundation

extension ReviewModel {
    struct FactorKey: Hashable {
        let categoryId: EntryCategory.ID
        let memo: String?
        let range: ClosedRange<LocalDate>
    }

    func entryCount(in range: ClosedRange<LocalDate>) -> Int {
        entries.count { range.contains($0.date) && $0.type != .transfer }
    }

    func goalShare(of item: ReviewGoalItem) -> Share? {
        guard
            let list,
            let id = item.goal.categoryId,
            let category = list.categories[id]
        else {
            return nil
        }

        let key = FactorKey(categoryId: id, memo: item.goal.memo, range: period.range)
        let amount = factorEntries(of: key).reduce(0) { $0 + $1.amount }

        return Share(
            id: AnyHashable(key),
            name: item.name,
            icon: list.icons[category.iconId],
            amount: amount,
            ratio: 0,
            usage: nil
        )
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
    func factorEntries(of key: FactorKey) -> [Entry] {
        entries.filter { entry in
            let isMemo = key.memo.map { ReviewBreakdown.normalized(entry.memo) == $0 } ?? true

            return entry.type == .expense
                && key.range.contains(entry.date)
                && entry.categoryId == key.categoryId
                && isMemo
        }
    }
}
