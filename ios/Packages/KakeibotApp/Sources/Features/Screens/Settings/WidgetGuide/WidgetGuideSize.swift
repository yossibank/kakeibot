enum WidgetGuideSize: Hashable {
    case small
    case medium
    case large
}

extension WidgetGuideSize {
    var title: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "大"
        }
    }
}
