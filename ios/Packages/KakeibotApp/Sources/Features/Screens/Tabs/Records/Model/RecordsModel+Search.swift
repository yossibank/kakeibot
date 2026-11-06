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
            expenseTotal: days.expenseTotal,
            incomeTotal: days.incomeTotal,
            range: first...last
        )
    }

    func restoreRecentSearches(_ words: [String]) async {
        do {
            try await database.setSetting(.recentSearches, to: words)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}
