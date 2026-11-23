import Core

struct ReviewYearProgress {
    let months: [Month]
    let spent: Int
    let previousSpent: Int?
}

extension ReviewYearProgress {
    struct Month: Identifiable {
        let id: Int
        let range: ClosedRange<LocalDate>
        let name: String
        let total: Int
        let state: State
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
