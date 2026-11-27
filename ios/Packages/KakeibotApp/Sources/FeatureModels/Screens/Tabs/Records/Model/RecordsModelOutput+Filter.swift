import Core
import Store

public extension RecordsModel.Output {
    var isMonthHiddenByFilter: Bool {
        guard
            !state.fields.filter.isEmpty,
            days.isEmpty,
            let list = input.list.value
        else {
            return false
        }

        return list.days.contains { period.contains($0.date) }
    }

    var isSearchHiddenByFilter: Bool {
        searchHiddenCount > 0
    }

    var shownEntryCount: Int {
        let isSearched = state.fields.isSearching && !EntrySearch(state.fields.searchText).isEmpty
        return Self.entryCount(in: isSearched ? searchDays : days)
    }
}
