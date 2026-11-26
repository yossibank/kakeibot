public struct ReviewPace: Hashable, Sendable {
    public let limit: Int
    public let basis: Basis
    public let spent: Int
    public let elapsedDays: Int
    public let totalDays: Int

    public init(
        limit: Int,
        basis: Basis,
        spent: Int,
        range: ClosedRange<LocalDate>,
        today: LocalDate
    ) {
        let total = range.upperBound.dayNumber - range.lowerBound.dayNumber + 1
        let elapsed = today.dayNumber - range.lowerBound.dayNumber + 1

        self.limit = limit
        self.basis = basis
        self.spent = spent
        self.totalDays = max(total, 1)
        self.elapsedDays = min(max(elapsed, 1), max(total, 1))
    }
}

public extension ReviewPace {
    enum Basis: Hashable, Sendable {
        case budget
        case average(periods: Int)
    }

    enum Verdict: Hashable, Sendable {
        case onTrack
        case fast
        case over
    }
}

public extension ReviewPace {
    var daysLeft: Int {
        totalDays - elapsedDays + 1
    }

    var usedRatio: Double {
        limit > 0 ? Double(spent) / Double(limit) : 1
    }

    var elapsedRatio: Double {
        Double(elapsedDays) / Double(totalDays)
    }

    var expected: Int {
        limit * elapsedDays / totalDays
    }

    var lead: Int {
        expected - spent
    }

    var remaining: Int {
        limit - spent
    }

    var perDay: Int {
        max(remaining, 0) / daysLeft
    }

    var projected: Int {
        spent * totalDays / elapsedDays
    }

    var projectedLeft: Int {
        limit - projected
    }

    var verdict: Verdict {
        if spent > limit {
            return .over
        }

        return spent <= expected ? .onTrack : .fast
    }
}
