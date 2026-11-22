import Foundation

public extension ReviewCompare {
    struct Why: Hashable, Sendable {
        public let parts: [Part]
        public let memo: String?

        public init(
            parts: [Part],
            memo: String?
        ) {
            self.parts = parts
            self.memo = memo
        }
    }

    static func why(
        entries: [Entry],
        categoryId: EntryCategory.ID,
        in range: ClosedRange<LocalDate>,
        history: [ClosedRange<LocalDate>]
    ) -> Why? {
        let expenses = entries.filter { entry in
            entry.type == .expense && entry.categoryId == categoryId
        }

        let recorded = history.filter { past in
            entries.contains { $0.type == .expense && past.contains($0.date) }
        }

        let current = expenses.filter { range.contains($0.date) }
        let pastCount = expenses.count { entry in recorded.contains { $0.contains(entry.date) } }
        let usualCount = pastCount / max(recorded.count, 1)
        let top = topMemo(current)
        let memo = top.map(memoParts)
        let weekend = weekendParts(current)

        let parts: [Why.Part] = switch (memo, weekend) {
        case let (memo?, weekend?): memo + [.text(" 件あり、")] + weekend + [.text("でした。")]
        case let (memo?, nil): memo + [.text(" 件ありました。")]
        case let (nil, weekend?): weekend + [.text("でした。")]
        case (nil, nil): countParts(current, usual: usualCount)
        }

        return Why(parts: parts, memo: top?.name)
    }
}

public extension ReviewCompare.Why {
    enum Part: Hashable, Sendable {
        case text(String)
        case number(String)
    }

    var text: String {
        parts.map { part in
            switch part {
            case let .text(text), let .number(text): text
            }
        }
        .joined()
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

    static func memoParts(_ top: (name: String, count: Int)) -> [Why.Part] {
        [.text("「\(top.name)」の記録が "), .number("\(top.count)")]
    }

    static func weekendParts(_ entries: [Entry]) -> [Why.Part]? {
        let weekend = entries.count { [.saturday, .sunday].contains($0.date.weekday) }

        let leans = entries.count >= 3
            && weekend * 2 > entries.count

        guard leans else {
            return nil
        }

        return [
            .number("\(entries.count)"),
            .text(" 件のうち "),
            .number("\(weekend)"),
            .text(" 件が土日")
        ]
    }

    static func countParts(
        _ entries: [Entry],
        usual: Int
    ) -> [Why.Part] {
        let total = entries.reduce(0) { $0 + $1.amount }
        let largest = entries.map(\.amount).max() ?? 0

        if entries.count > usual {
            return [
                .text("記録が "),
                .number("\(entries.count)"),
                .text(" 件で、いつもの "),
                .number("\(usual)"),
                .text(" 件より多めでした。")
            ]
        }

        if entries.count >= 2,
           largest * 2 >= total {
            return [
                .number(ReviewYen.number(largest)),
                .text("円 の記録が "),
                .number("1"),
                .text(" 件ありました。")
            ]
        }

        return [.text("1 回あたりの額が、いつもより高めでした。")]
    }
}
