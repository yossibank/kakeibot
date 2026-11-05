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
        searchHiddenCount > 0
    }

    var searchHiddenCount: Int {
        let search = EntrySearch(searchText)

        guard
            !filter.isEmpty,
            !search.isEmpty,
            searchDays.isEmpty,
            let list
        else {
            return 0
        }

        return Self.entryCount(in: list.days(matching: search))
    }

    var shownEntryCount: Int {
        let isSearched = isSearching && !EntrySearch(searchText).isEmpty
        return Self.entryCount(in: isSearched ? searchDays : days)
    }

    func clearFilter() {
        filter = EntryFilter()
    }
}

private extension RecordsModel {
    static func entryCount(in days: [EntryDay]) -> Int {
        days.reduce(0) { $0 + $1.entries.count }
    }
}
