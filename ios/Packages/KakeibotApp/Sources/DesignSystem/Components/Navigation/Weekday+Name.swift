import Core

public extension Weekday {
    var shortName: String {
        switch self {
        case .monday: "月"
        case .tuesday: "火"
        case .wednesday: "水"
        case .thursday: "木"
        case .friday: "金"
        case .saturday: "土"
        case .sunday: "日"
        }
    }
}
