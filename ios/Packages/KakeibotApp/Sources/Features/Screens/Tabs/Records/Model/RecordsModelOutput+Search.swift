import Core
import Store

public extension RecordsModel.Output {
    var searchSummary: RecordsModel.SearchSummary? {
        let days = searchDays

        guard
            let first = days.last?.date,
            let last = days.first?.date
        else {
            return nil
        }

        return RecordsModel.SearchSummary(
            count: days.reduce(0) { $0 + $1.entries.count },
            expenseTotal: days.expenseTotal,
            incomeTotal: days.incomeTotal,
            range: first...last
        )
    }
}
