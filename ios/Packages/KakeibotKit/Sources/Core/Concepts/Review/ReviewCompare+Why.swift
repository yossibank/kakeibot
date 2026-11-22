import Foundation

public extension ReviewCompare {
    static func why(
        entries: [Entry],
        categoryId: EntryCategory.ID,
        in range: ClosedRange<LocalDate>,
        history: [ClosedRange<LocalDate>]
    ) -> String? {
        let expenses = entries.filter { entry in
            entry.type == .expense && entry.categoryId == categoryId
        }

        let recorded = history.filter { past in
            entries.contains { $0.type == .expense && past.contains($0.date) }
        }

        let current = expenses.filter { range.contains($0.date) }
        let pastCount = expenses.count { entry in recorded.contains { $0.contains(entry.date) } }
        let usualCount = pastCount / max(recorded.count, 1)
        let memo = topMemo(current).map { "「\($0.name)」の記録が \($0.count) 件" }
        let weekend = weekendText(current)

        return switch (memo, weekend) {
        case let (memo?, weekend?): "\(memo)あり、\(weekend)でした。"
        case let (memo?, nil): "\(memo)ありました。"
        case let (nil, weekend?): "\(weekend)でした。"
        case (nil, nil): countText(current, usual: usualCount)
        }
    }
}

private extension ReviewCompare {
    static func topMemo(_ entries: [Entry]) -> (name: String, count: Int)? {
        let memos = entries.compactMap { ReviewGoal.normalizedMemo($0.memo) }
        let counts = Dictionary(memos.map { ($0, 1) }, uniquingKeysWith: +)

        let top = counts.max { lhs, rhs in
            lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
        }

        guard
            let top,
            top.value >= ReviewGoal.memoMinimum
        else {
            return nil
        }

        return (top.key, top.value)
    }

    static func weekendText(_ entries: [Entry]) -> String? {
        let weekend = entries.count { [.saturday, .sunday].contains($0.date.weekday) }

        let leans = entries.count >= 3
            && weekend * 2 > entries.count

        return leans ? "\(entries.count) 件のうち \(weekend) 件が土日" : nil
    }

    static func countText(
        _ entries: [Entry],
        usual: Int
    ) -> String {
        let total = entries.reduce(0) { $0 + $1.amount }
        let largest = entries.map(\.amount).max() ?? 0

        if entries.count > usual {
            return "記録が \(entries.count) 件で、いつもの \(usual) 件より多めでした。"
        }

        if entries.count >= 2,
           largest * 2 >= total {
            return "\(ReviewYen.text(largest)) の記録が 1 件ありました。"
        }

        return "1 回あたりの額が、いつもより高めでした。"
    }
}
