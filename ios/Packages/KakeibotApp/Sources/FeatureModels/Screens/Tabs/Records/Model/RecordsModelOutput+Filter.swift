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

    var filterTagCategories: [EntryCategory] {
        let categories = input.list.value?.filterCategories ?? []
        let chosen = state.fields.filter.categoryIds
        return chosen.isEmpty ? categories : categories.filter { chosen.contains($0.id) }
    }

    var shownFilterTagIds: Set<EntryTag.ID> {
        Set(filterTagCategories.flatMap { filterTags(in: $0.id) }.map(\.id))
    }

    var shownEntryCount: Int {
        let isSearched = state.fields.isSearching && !EntrySearch(state.fields.searchText).isEmpty
        return Self.entryCount(in: isSearched ? searchDays : days)
    }

    func filterCategories(of kind: EntryCategory.Kind) -> [EntryCategory] {
        (input.list.value?.filterCategories ?? []).filter { $0.kind == kind }
    }

    func chosenCategoryCount(of kind: EntryCategory.Kind) -> Int {
        filterCategories(of: kind)
            .filter { state.fields.filter.categoryIds.contains($0.id) }
            .count
    }

    func filterTags(in categoryId: EntryCategory.ID) -> [EntryTag] {
        (input.list.value?.filterTags ?? []).filter { $0.categoryId == categoryId }
    }
}
