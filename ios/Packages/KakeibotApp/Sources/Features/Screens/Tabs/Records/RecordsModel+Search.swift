import Core
import Store

public extension RecordsModel {
    struct SearchSummary: Equatable {
        public let count: Int
        public let expenseTotal: Int
        public let incomeTotal: Int
        public let range: ClosedRange<LocalDate>
    }

    var searchSummary: SearchSummary? {
        let days = searchDays

        guard
            let first = days.last?.date,
            let last = days.first?.date
        else {
            return nil
        }

        return SearchSummary(
            count: days.reduce(0) { $0 + $1.entries.count },
            expenseTotal: days.reduce(0) { $0 + $1.expenseTotal },
            incomeTotal: days.reduce(0) { $0 + $1.incomeTotal },
            range: first...last
        )
    }
}
