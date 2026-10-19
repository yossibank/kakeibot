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
    func icon(on date: LocalDate) -> Icon? {
        stamps[date].flatMap { icons[$0.iconId] }
    }
}
