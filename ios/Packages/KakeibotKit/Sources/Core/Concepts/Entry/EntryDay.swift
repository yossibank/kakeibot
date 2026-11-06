public struct EntryDay: Hashable, Sendable {
    public let date: LocalDate
    public let entries: [Entry]
    public let expenseTotal: Int
    public let incomeTotal: Int

    public init(
        date: LocalDate,
        entries: [Entry]
    ) {
        self.date = date
        self.entries = entries
        self.expenseTotal = Self.total(of: .expense, in: entries)
        self.incomeTotal = Self.total(of: .income, in: entries)
    }
}

public extension EntryDay {
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

public extension Sequence<EntryDay> {
    var expenseTotal: Int {
        reduce(0) { $0 + $1.expenseTotal }
    }

    var incomeTotal: Int {
        reduce(0) { $0 + $1.incomeTotal }
    }
}

public extension [EntryDay] {
    func within(_ range: ClosedRange<LocalDate>) -> [EntryDay] {
        filter { range.contains($0.date) }
    }

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

    static func total(
        of type: Entry.Kind,
        in entries: [Entry]
    ) -> Int {
        entries
            .filter { $0.type == type }
            .reduce(0) { $0 + $1.amount }
    }
}
