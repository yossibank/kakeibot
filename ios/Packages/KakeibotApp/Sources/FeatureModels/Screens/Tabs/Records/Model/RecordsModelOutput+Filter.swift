import Core
import Store

public extension RecordsModel.Output {
    var isMonthHiddenByFilter: Bool {
        guard
            !state.filter.isEmpty,
            days.isEmpty,
            let list = input.list
        else {
            return false
        }

        return list.days.contains { period.contains($0.date) }
    }

    var isSearchHiddenByFilter: Bool {
        searchHiddenCount > 0
    }

    var shownEntryCount: Int {
        let isSearched = state.isSearching && !EntrySearch(state.searchText).isEmpty
        return Self.entryCount(in: isSearched ? searchDays : days)
    }
}
