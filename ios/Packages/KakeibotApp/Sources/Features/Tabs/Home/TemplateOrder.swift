import Foundation

public enum TemplateOrder: String, CaseIterable, Identifiable, Sendable {
    case manual
    case category
    case amount
    case name
}

public extension TemplateOrder {
    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .manual: "並べた順"
        case .category: "カテゴリ順"
        case .amount: "金額が大きい順"
        case .name: "名前順"
        }
    }
}
