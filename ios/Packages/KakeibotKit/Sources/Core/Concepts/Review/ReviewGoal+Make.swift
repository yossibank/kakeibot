import Foundation

public extension ReviewGoal {
    static let memoMinimum = 2

    static func make(
        entries: [Entry],
        closed range: ClosedRange<LocalDate>,
        history: [ClosedRange<LocalDate>],
        period: String,
        now: Date
    ) -> ReviewGoal? {
        let compare = ReviewCompare(entries: entries, in: range, history: history)

        guard let row = compare.rows.first(where: { $0.tone == .more }) else {
            return nil
        }

        let expenses = entries.filter { entry in
            entry.type == .expense
                && entry.categoryId == row.categoryId
                && entry.id != compare.special?.id
        }

        let recorded = history.filter { past in
            entries.contains { $0.type == .expense && past.contains($0.date) }
        }

        let current = expenses.filter { range.contains($0.date) }
        let past = expenses.filter { entry in recorded.contains { $0.contains(entry.date) } }
        let memo = focusMemo(current: current, past: past, periods: recorded.count)
        let scope = Scope(current: current, past: past, memo: memo, periods: recorded.count)

        guard scope.count > 0 else {
            return nil
        }

        let shape = scope.countEffect >= scope.priceEffect && scope.count >= 2
            ? countGoal(scope)
            : averageGoal(scope)

        guard let shape else {
            return nil
        }

        return ReviewGoal(
            period: period,
            kind: shape.kind,
            categoryId: row.categoryId,
            memo: memo,
            baseline: shape.baseline,
            target: shape.target,
            saving: shape.saving,
            createdAt: now
        )
    }

    static func normalizedMemo(_ memo: String?) -> String? {
        let trimmed = memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed.precomposedStringWithCompatibilityMapping
    }

    func checked(
        entries: [Entry],
        in range: ClosedRange<LocalDate>,
        now: Date
    ) -> ReviewGoal {
        let progress = progress(of: entries, in: range, today: range.upperBound)
        let result = current(of: progress)
        let reduced = max(baseline - result, 0)

        var goal = self

        goal.result = result
        goal.checkedAt = now

        switch kind {
        case .count:
            goal.saved = reduced * saving / max(baseline - target, 1)

        case .average:
            goal.saved = reduced * progress.count
        }

        return goal
    }
}

private extension ReviewGoal {
    struct Scope {
        let count: Int
        let amount: Int
        let pastCount: Double
        let pastAmount: Double

        var unitPrice: Int {
            count > 0 ? amount / count : 0
        }

        var pastUnitPrice: Int {
            pastCount > 0 ? Int(pastAmount / pastCount) : unitPrice
        }

        var countEffect: Double {
            (Double(count) - pastCount) * Double(pastUnitPrice)
        }

        var priceEffect: Double {
            Double(unitPrice - pastUnitPrice) * Double(count)
        }

        init(
            current: [Entry],
            past: [Entry],
            memo: String?,
            periods: Int
        ) {
            let matches: (Entry) -> Bool = { entry in
                memo == nil || ReviewGoal.normalizedMemo(entry.memo) == memo
            }

            let now = current.filter(matches)
            let before = past.filter(matches)
            let divisor = Double(max(periods, 1))

            self.count = now.count
            self.amount = now.reduce(0) { $0 + $1.amount }
            self.pastCount = Double(before.count) / divisor
            self.pastAmount = Double(before.reduce(0) { $0 + $1.amount }) / divisor
        }
    }

    struct Shape {
        let kind: Kind
        let baseline: Int
        let target: Int
        let saving: Int
    }

    static func focusMemo(
        current: [Entry],
        past: [Entry],
        periods: Int
    ) -> String? {
        let names = Set(current.compactMap { normalizedMemo($0.memo) })

        let rises = names.map { name in
            let now = current.count { normalizedMemo($0.memo) == name }
            let before = past.count { normalizedMemo($0.memo) == name }
            let rise = Double(now) - Double(before) / Double(max(periods, 1))

            return (name: name, rise: rise)
        }

        let best = rises
            .filter { $0.rise >= Double(memoMinimum) }
            .max { lhs, rhs in
                lhs.rise == rhs.rise ? lhs.name > rhs.name : lhs.rise < rhs.rise
            }

        return best?.name
    }

    static func countGoal(_ scope: Scope) -> Shape? {
        let middle = Int(((Double(scope.count) + scope.pastCount) / 2).rounded())
        let target = max(min(middle, scope.count - 1), 1)

        guard target < scope.count else {
            return averageGoal(scope)
        }

        return Shape(
            kind: .count,
            baseline: scope.count,
            target: target,
            saving: (scope.count - target) * scope.unitPrice
        )
    }

    static func averageGoal(_ scope: Scope) -> Shape? {
        let middle = (scope.unitPrice + scope.pastUnitPrice) / 2
        let target = middle / 10 * 10

        guard target < scope.unitPrice else {
            return nil
        }

        return Shape(
            kind: .average,
            baseline: scope.unitPrice,
            target: target,
            saving: (scope.unitPrice - target) * scope.count
        )
    }
}
