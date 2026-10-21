import Core

public extension EntryStyle {
    var isReady: Bool {
        switch self {
        case .dial: true
        case .card, .ring: false
        }
    }
}

extension EntryStyle {
    var title: String {
        switch self {
        case .dial: "夜のダイヤル"
        case .card: "カード"
        case .ring: "円形のカテゴリ"
        }
    }

    var note: String {
        switch self {
        case .dial: "金額を目盛りで囲み、押すとテンキーを出します"
        case .card: "カテゴリと金額をカードに並べて入れます"
        case .ring: "カテゴリを円に並べ、回して選びます"
        }
    }

    var systemImage: String {
        switch self {
        case .dial: "dial.medium"
        case .card: "rectangle.stack"
        case .ring: "circle.circle"
        }
    }
}
