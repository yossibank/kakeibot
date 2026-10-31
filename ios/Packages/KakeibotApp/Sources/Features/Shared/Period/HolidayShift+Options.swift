import Core
import DesignSystem

extension HolidayShift {
    static var options: [CapsulePicker<HolidayShift>.Option] {
        allCases.map { .init($0.title, value: $0) }
    }

    var title: String {
        switch self {
        case .none: "そのまま"
        case .previous: "前の平日"
        case .next: "次の平日"
        }
    }
}
