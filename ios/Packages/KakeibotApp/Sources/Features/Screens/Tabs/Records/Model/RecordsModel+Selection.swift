import Core

public extension RecordsModel {
    var shownEntryIDs: [Entry.ID] {
        let shown = isSearching ? searchDays : days
        return shown.flatMap(\.entries).map(\.id)
    }

    func isSelected(
        _ day: EntryDay,
        in selection: Set<Entry.ID>
    ) -> Bool {
        !day.entries.isEmpty && day.entries.allSatisfy { entry in
            selection.contains(entry.id)
        }
    }

    func toggling(
        _ id: Entry.ID,
        in selection: Set<Entry.ID>
    ) -> Set<Entry.ID> {
        selection.contains(id) ? selection.subtracting([id]) : selection.union([id])
    }

    func toggling(
        _ day: EntryDay,
        in selection: Set<Entry.ID>
    ) -> Set<Entry.ID> {
        let ids = day.entries.map(\.id)
        return isSelected(day, in: selection) ? selection.subtracting(ids) : selection.union(ids)
    }

    func selectingAllShown(in selection: Set<Entry.ID>) -> Set<Entry.ID> {
        selection.union(shownEntryIDs)
    }

    func selectsAllShown(_ selection: Set<Entry.ID>) -> Bool {
        let shown = shownEntryIDs
        return !shown.isEmpty && selection.isSuperset(of: shown)
    }
}
