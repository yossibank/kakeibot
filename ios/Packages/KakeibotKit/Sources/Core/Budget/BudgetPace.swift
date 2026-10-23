public struct BudgetPace: Hashable, Sendable {
    public let projectedLeft: Int

    public init(
        budget: Int,
        spent: Int,
        fixedSpent: Int,
        upcoming: Int,
        today: LocalDate,
        period: ClosedRange<LocalDate>
    ) {
        let elapsed = max(today.dayNumber - period.lowerBound.dayNumber + 1, 1)
        let restDays = max(period.upperBound.dayNumber - today.dayNumber, 0)
        let variable = max(spent - fixedSpent, 0)
        let projected = spent + upcoming + variable * restDays / elapsed

        self.projectedLeft = budget - projected
    }
}

public extension BudgetPace {
    var isShort: Bool {
        projectedLeft < 0
    }
}
