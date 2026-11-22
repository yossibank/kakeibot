public struct ReviewStreak: Hashable, Sendable {
    public let days: Set<LocalDate>
    public let noSpendDays: Set<LocalDate>
    public let longest: Int
    public let count: Int

    public init(
        entries: [Entry],
        noSpendDays: Set<LocalDate> = [],
        in range: ClosedRange<LocalDate>
    ) {
        let recorded = entries.filter { range.contains($0.date) && $0.recurringId == nil }
        let entryDays = Set(recorded.map(\.date))
        let quietDays = noSpendDays.filter { range.contains($0) }.subtracting(entryDays)
        let days = entryDays.union(quietDays)

        var longest = 0
        var run = 0
        var day = range.lowerBound

        while day <= range.upperBound {
            run = days.contains(day) ? run + 1 : 0
            longest = max(longest, run)
            day = day.adding(days: 1)
        }

        self.days = days
        self.noSpendDays = quietDays
        self.longest = longest
        self.count = recorded.count
    }
}

public extension ReviewStreak {
    static func continuing(
        entries: [Entry],
        noSpendDays: Set<LocalDate> = [],
        periods: [ClosedRange<LocalDate>]
    ) -> Int {
        let recorded = entries.filter { $0.recurringId == nil }

        let index = periods.firstIndex { range in
            let hasEntry = recorded.contains { range.contains($0.date) }
            let hasNoSpendDay = noSpendDays.contains { range.contains($0) }
            return !hasEntry && !hasNoSpendDay
        }

        return index ?? periods.count
    }
}
