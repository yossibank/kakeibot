import Core

extension ThemeStyle {
    var title: String {
        let fonts = displayFont == textFont
            ? displayFont.title
            : "\(displayFont.title)と\(textFont.title)"

        guard textSize == .standard else {
            return "文字\(textSize.title)・\(fonts)"
        }

        return "\(fonts)・角\(corner.title)"
    }

    var shortTitle: String {
        guard textSize == .standard else {
            return "文字\(textSize.title)"
        }

        return title
    }
}

extension ThemeTextSize {
    var title: String {
        switch self {
        case .small: "小さめ"
        case .standard: "ふつう"
        case .large: "大きめ"
        }
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
