import Core

public extension TemplateOrder {
    var title: String {
        switch self {
        case .manual: "並べた順"
        case .frequent: "よく使う順"
        case .category: "カテゴリ順"
        case .amount: "金額が大きい順"
        case .name: "名前順"
        }
    }

    var note: String? {
        switch self {
        case .manual: "設定で並べ替えられます"
        case .frequent: "この \(Self.frequentDays) 日に記録した回数の順です"
        case .category, .amount, .name: nil
        }
    }

    var systemImage: String {
        switch self {
        case .manual: "line.3.horizontal"
        case .frequent: "flame"
        case .category: "square.grid.2x2"
        case .amount: "yensign"
        case .name: "textformat"
        }
    }
}
