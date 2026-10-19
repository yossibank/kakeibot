import Core

public struct StampCalendar: Equatable, Sendable {
    public let stamps: [LocalDate: CalendarStamp]
    public let icons: [Icon.ID: Icon]

    public init(
        stamps: [LocalDate: CalendarStamp],
        icons: [Icon.ID: Icon]
    ) {
        self.stamps = stamps
        self.icons = icons
    }
}

public extension StampCalendar {
    struct Tally: Identifiable, Equatable, Sendable {
        public let icon: Icon
        public let count: Int
        public let lastDate: LocalDate

        public var id: Icon.ID {
            icon.id
        }
    }

    func icon(on date: LocalDate) -> Icon? {
        stamps[date].flatMap { icons[$0.iconId] }
    }

    func tallies(in range: ClosedRange<LocalDate>) -> [Tally] {
        let inRange = stamps.values.filter { range.contains($0.date) }
        let groups = Dictionary(grouping: inRange, by: \.iconId)

        let tallies = groups.compactMap { iconId, stamps -> Tally? in
            guard
                let icon = icons[iconId],
                let lastDate = stamps.map(\.date).max()
            else {
                return nil
            }

            return Tally(icon: icon, count: stamps.count, lastDate: lastDate)
        }

        return tallies.sorted { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count > rhs.count
            }

            return lhs.lastDate > rhs.lastDate
        }
    }
}
