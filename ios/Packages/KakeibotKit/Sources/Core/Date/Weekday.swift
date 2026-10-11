public enum Weekday: String, CaseIterable, Codable, Sendable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

extension Weekday {
    var daysSinceMonday: Int {
        switch self {
        case .monday: 0
        case .tuesday: 1
        case .wednesday: 2
        case .thursday: 3
        case .friday: 4
        case .saturday: 5
        case .sunday: 6
        }
    }

    init(daysSinceMonday days: Int) {
        let index = (days % 7 + 7) % 7
        self = Self.allCases[index]
    }
}
