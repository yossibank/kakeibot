public struct ReviewCompare: Hashable, Sendable {
    public let rows: [Row]
    public let special: Entry?
    public let periods: Int

    public init(
        entries: [Entry],
        in range: ClosedRange<LocalDate>,
        history: [ClosedRange<LocalDate>]
    ) {
        let expenses = entries.filter { $0.type == .expense && $0.categoryId != nil }
        let current = expenses.filter { range.contains($0.date) }

        let recorded = history.filter { past in
            expenses.contains { past.contains($0.date) }
        }

        var sums: [EntryCategory.ID: Int] = [:]

        for entry in expenses where recorded.contains(where: { $0.contains(entry.date) }) {
            if let categoryId = entry.categoryId {
                sums[categoryId, default: 0] += entry.amount
            }
        }

        let averages = recorded.isEmpty ? [:] : sums.mapValues { $0 / recorded.count }
        let special = Self.special(in: current, averages: averages)

        var totals: [EntryCategory.ID: Int] = [:]

        for entry in current where entry.id != special?.id {
            if let categoryId = entry.categoryId {
                totals[categoryId, default: 0] += entry.amount
            }
        }

        let categories = Set(totals.keys).union(averages.keys)

        self.periods = recorded.count
        self.special = special

        self.rows = recorded.isEmpty
            ? []
            : categories
                .map { id in
                    Row(
                        categoryId: id,
                        amount: totals[id, default: 0],
                        average: averages[id, default: 0]
                    )
                }
                .sorted { abs($0.difference) > abs($1.difference) }
    }
}

public extension ReviewCompare {
    struct Row: Hashable, Sendable {
        public let categoryId: EntryCategory.ID
        public let amount: Int
        public let average: Int

        public init(
            categoryId: EntryCategory.ID,
            amount: Int,
            average: Int
        ) {
            self.categoryId = categoryId
            self.amount = amount
            self.average = average
        }
    }

    enum Tone: Hashable, Sendable {
        case more
        case less
        case usual
    }
}

public extension ReviewCompare {
    static let specialMinimum = 10000
    static let usualMinimum = 500

    static func tone(
        amount: Int,
        average: Int
    ) -> Tone {
        let difference = amount - average
        let margin = max(average / 10, usualMinimum)

        if abs(difference) <= margin {
            return .usual
        }

        return difference > 0 ? .more : .less
    }
}

private extension ReviewCompare {
    static func special(
        in entries: [Entry],
        averages: [EntryCategory.ID: Int]
    ) -> Entry? {
        entries
            .filter { entry in
                let average = entry.categoryId.flatMap { averages[$0] } ?? 0
                return entry.amount >= specialMinimum && entry.amount >= average * 2
            }
            .max { $0.amount < $1.amount }
    }
}

public extension ReviewCompare.Row {
    var difference: Int {
        amount - average
    }

    var tone: ReviewCompare.Tone {
        ReviewCompare.tone(amount: amount, average: average)
    }
}
