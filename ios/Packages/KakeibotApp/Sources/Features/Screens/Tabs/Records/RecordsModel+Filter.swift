import Core
import Store

public extension RecordsModel {
    var isMonthHiddenByFilter: Bool {
        guard
            !filter.isEmpty,
            days.isEmpty,
            let list
        else {
            return false
        }

        return list.days.contains { period.contains($0.date) }
    }

    var isSearchHiddenByFilter: Bool {
        let search = EntrySearch(searchText)

        guard
            !filter.isEmpty,
            !search.isEmpty,
            searchDays.isEmpty,
            let list
        else {
            return false
        }

        return !list.days(matching: search).isEmpty
    }

    func clearFilter() {
        filter = EntryFilter()
    }
}
