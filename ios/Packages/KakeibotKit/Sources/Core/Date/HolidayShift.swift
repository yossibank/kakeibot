public enum HolidayShift: String, CaseIterable, Codable, Sendable {
    case none
    case previous
    case next

    public func apply(to date: LocalDate) -> LocalDate {
        let step = switch self {
        case .none: 0
        case .previous: -1
        case .next: 1
        }

        guard step != 0 else {
            return date
        }

        var shifted = date

        while Holiday.isDayOff(shifted) {
            shifted = shifted.adding(days: step)
        }

        return shifted
    }
}
