public struct EntryFilter: Hashable, Sendable {
    public var categoryIds: Set<EntryCategory.ID>

    public init(categoryIds: Set<EntryCategory.ID> = []) {
        self.categoryIds = categoryIds
    }
}

public extension EntryFilter {
    var isEmpty: Bool {
        categoryIds.isEmpty
    }

    func includes(_ entry: Entry) -> Bool {
        guard !isEmpty else {
            return true
        }

        guard let categoryId = entry.categoryId else {
            return false
        }

        return categoryIds.contains(categoryId)
    }

    func apply(to days: [EntryDay]) -> [EntryDay] {
        guard !isEmpty else {
            return days
        }

        let entries = days.flatMap(\.entries).filter(includes)
        return EntryDay.grouping(entries)
    }
}
