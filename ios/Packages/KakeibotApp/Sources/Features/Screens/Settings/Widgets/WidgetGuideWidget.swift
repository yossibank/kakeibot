enum WidgetGuideWidget: CaseIterable, Hashable {
    case budget
    case quickRecord
}

enum WidgetGuideSize: Hashable {
    case small
    case medium
    case large
}

extension WidgetGuideWidget {
    var title: String {
        switch self {
        case .budget: "あといくら"
        case .quickRecord: "すぐ記録"
        }
    }

    var sizes: [WidgetGuideSize] {
        switch self {
        case .budget: [.small, .medium]
        case .quickRecord: [.medium, .large]
        }
    }
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
