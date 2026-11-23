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
        guard let id = item.goal.categoryId else {
            return nil
        }

        return factorShare(
            categoryId: id,
            memo: item.goal.memo,
            name: item.name
        )
    }

    func whyShare(
        of row: ReviewClosingView.CompareRow,
        why: ReviewCompare.Why
    ) -> Share? {
        let name = why.memo.map { "\(row.name) · \($0)" } ?? row.name

        return factorShare(
            categoryId: row.id,
            memo: why.memo,
            name: name
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
    func factorShare(
        categoryId: EntryCategory.ID,
        memo: String?,
        name: String
    ) -> Share? {
        guard
            let list,
            let category = list.categories[categoryId]
        else {
            return nil
        }

        let key = FactorKey(categoryId: categoryId, memo: memo, range: period.range)
        let amount = factorEntries(of: key).reduce(0) { $0 + $1.amount }

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
        entries.filter { entry in
            let isMemo = key.memo.map { ReviewGoal.normalizedMemo(entry.memo) == $0 } ?? true

            return entry.type == .expense
                && key.range.contains(entry.date)
                && entry.categoryId == key.categoryId
                && isMemo
        }
    }
}
