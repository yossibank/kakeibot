public struct BudgetUsage: Hashable, Sendable {
    public let budget: Int
    public let spent: Int
    public let daysLeft: Int

    public init(
        budget: Int,
        spent: Int,
        today: LocalDate,
        periodEnd: LocalDate
    ) {
        let days = periodEnd.dayNumber - today.dayNumber + 1

        self.budget = budget
        self.spent = spent
        self.daysLeft = max(days, 1)
    }
}

public extension BudgetUsage {
    var remaining: Int {
        budget - spent
    }

    var isOver: Bool {
        spent > budget
    }

    var isNearLimit: Bool {
        budget > 0 && !isOver && spent * 5 >= budget * 4
    }

    var progress: Double {
        guard budget > 0 else {
            return 1
        }

        let ratio = Double(spent) / Double(budget)

        return min(ratio, 1)
    }
}
