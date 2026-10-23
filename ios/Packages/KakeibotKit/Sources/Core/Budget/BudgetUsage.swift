public struct BudgetUsage: Hashable, Sendable {
    public let budget: Int
    public let spent: Int
    public let upcoming: Int
    public let daysLeft: Int

    public init(
        budget: Int,
        spent: Int,
        upcoming: Int = 0,
        today: LocalDate,
        periodEnd: LocalDate
    ) {
        self.budget = budget
        self.spent = spent
        self.upcoming = upcoming
        self.daysLeft = max(periodEnd.dayNumber - today.dayNumber + 1, 1)
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
        !isOver && spent * 5 >= budget * 4
    }

    var perDay: Int {
        max(remaining - upcoming, 0) / daysLeft
    }

    var progress: Double {
        guard budget > 0 else {
            return 1
        }

        return min(Double(spent) / Double(budget), 1)
    }

    func todayRemaining(spentToday: Int) -> Int {
        let usable = max(remaining + spentToday - upcoming, 0)

        return usable / daysLeft - spentToday
    }
}
