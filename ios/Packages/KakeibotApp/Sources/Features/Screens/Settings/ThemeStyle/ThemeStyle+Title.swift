import Core

extension ThemeStyle {
    var title: String {
        guard displayFont != textFont else {
            return "\(corner.title)・\(displayFont.title)"
        }

        return "\(corner.title)・\(displayFont.title)と\(textFont.title)"
    }
}

extension ThemeCorner {
    var title: String {
        switch self {
        case .square: "なし"
        case .small: "小さめ"
        case .standard: "ふつう"
        case .large: "大きめ"
        }
    }
}

extension ThemeFont {
    var title: String {
        switch self {
        case .mincho: "明朝"
        case .gothic: "ゴシック"
        case .rounded: "丸ゴシック"
        case .handwriting: "手書き"
        case .dot: "ドット"
        }
    }
}
