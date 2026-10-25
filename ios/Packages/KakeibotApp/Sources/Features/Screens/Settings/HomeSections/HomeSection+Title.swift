import Core

extension HomeSection {
    var title: String {
        switch self {
        case .budget: "予算"
        case .setup: "準備のカード"
        case .templates: "テンプレート"
        case .recent: "最近の記録"
        }
    }

    var systemImage: String {
        switch self {
        case .budget: "gauge.with.dots.needle.33percent"
        case .setup: "checklist"
        case .templates: "rectangle.stack"
        case .recent: "list.bullet"
        }
    }
}
