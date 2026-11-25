public enum WidgetGuideSize: Hashable, Sendable {
    case small
    case medium
    case large
}

public extension WidgetGuideSize {
    var title: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "大"
        }
    }
}
