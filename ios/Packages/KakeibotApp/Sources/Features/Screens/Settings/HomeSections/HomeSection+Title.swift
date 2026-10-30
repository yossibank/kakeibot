import Core

extension HomeSection {
    var title: String {
        switch self {
        case .customize: "自分好みにカスタマイズ"
        case .budget: "予算"
        case .templates: "テンプレート"
        case .recent: "最近の記録"
        case .bills: "これからの引き落とし"
        case .stamps: "押したスタンプ"
        }
    }
}
