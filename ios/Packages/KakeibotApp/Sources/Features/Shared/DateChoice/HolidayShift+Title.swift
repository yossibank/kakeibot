import Core

extension HolidayShift {
    var title: String {
        switch self {
        case .none: "そのまま"
        case .previous: "前の平日"
        case .next: "次の平日"
        }
    }
}
