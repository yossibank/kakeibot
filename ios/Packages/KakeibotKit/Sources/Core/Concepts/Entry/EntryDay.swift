public struct EntryDay: Hashable, Sendable {
    public let date: LocalDate
    public let entries: [Entry]
}

public extension EntryDay {
    var expenseTotal: Int {
        total(of: .expense)
    }

    var incomeTotal: Int {
        total(of: .income)
    }

    static func grouping(
        _ entries: [Entry],
        categories: [EntryCategory.ID: EntryCategory] = [:]
    ) -> [EntryDay] {
        Dictionary(grouping: entries, by: \.date)
            .map { date, entries in
                let sorted = entries.sorted { lhs, rhs in
                    isBefore(lhs, rhs, categories: categories)
                }

                return EntryDay(date: date, entries: sorted)
            }
            .sorted { $0.date > $1.date }
    }
}

public extension [EntryDay] {
    func filtered(by isIncluded: (Entry) -> Bool) -> [EntryDay] {
        compactMap { day in
            let entries = day.entries.filter(isIncluded)
            return entries.isEmpty ? nil : EntryDay(date: day.date, entries: entries)
        }
    }
}

private extension EntryDay {
    static func isBefore(
        _ lhs: Entry,
        _ rhs: Entry,
        categories: [EntryCategory.ID: EntryCategory]
    ) -> Bool {
        let lhsRank = rank(of: lhs, in: categories)
        let rhsRank = rank(of: rhs, in: categories)

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        return isNewer(lhs, than: rhs)
    }

    static func rank(
        of entry: Entry,
        in categories: [EntryCategory.ID: EntryCategory]
    ) -> (Int, Int) {
        guard
            let id = entry.categoryId,
            let category = categories[id]
        else {
            return (2, 0)
        }

        let kind = category.kind == .expense ? 0 : 1
        return (kind, category.sortOrder)
    }

    static func isNewer(
        _ lhs: Entry,
        than rhs: Entry
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.id.description < rhs.id.description
    }

    func total(of type: Entry.Kind) -> Int {
        entries.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }
}
