import Core

public struct ReviewYearProgress {
    public let months: [Month]
    public let spent: Int
    public let previousSpent: Int?
}

public extension ReviewYearProgress {
    struct Month: Identifiable {
        public let id: Int

        let range: ClosedRange<LocalDate>

        public let name: String
        public let total: Int
        public let state: State

        let isWithinBudget: Bool?
    }

    enum State {
        case closed
        case current
        case upcoming
    }

    var closedMonths: [Month] {
        months.filter { $0.state == .closed && $0.total > 0 }
    }

    var average: Int? {
        let closed = closedMonths

        guard !closed.isEmpty else {
            return nil
        }

        return closed.map(\.total).reduce(0, +) / closed.count
    }

    var peak: Month? {
        closedMonths.max { $0.total < $1.total }
    }

    var budgetedCount: Int {
        months.filter { $0.isWithinBudget != nil }.count
    }

    var withinBudgetCount: Int {
        months.filter { $0.isWithinBudget == true }.count
    }

    var largest: Int {
        months.map(\.total).max() ?? 0
    }
}
