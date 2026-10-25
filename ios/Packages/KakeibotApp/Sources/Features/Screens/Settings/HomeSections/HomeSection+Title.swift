import Core

extension HomeSection {
    var title: String {
        switch self {
        case .budget: "予算"
        case .templates: "テンプレート"
        case .recent: "最近の記録"
        }
    }
}
