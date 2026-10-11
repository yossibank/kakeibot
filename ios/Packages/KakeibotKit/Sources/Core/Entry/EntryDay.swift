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

    static func grouping(_ entries: [Entry]) -> [EntryDay] {
        Dictionary(grouping: entries, by: \.date)
            .map { date, entries in
                let sorted = entries.sorted(by: isNewer)
                return EntryDay(date: date, entries: sorted)
            }
            .sorted { $0.date > $1.date }
    }
}

private extension EntryDay {
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
        entries
            .filter { $0.type == type }
            .reduce(0) { $0 + $1.amount }
    }
}
