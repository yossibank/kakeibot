import Core

extension ThemeStyle {
    var title: String {
        let size = textSize == .standard ? [] : ["文字\(textSize.title)"]

        let fonts = displayFont == textFont
            ? displayFont.title
            : "\(displayFont.title)と\(textFont.title)"

        return (size + [fonts, "角\(corner.title)"]).joined(separator: "・")
    }
}

extension ThemeTextSize {
    var title: String {
        switch self {
        case .small: "小さめ"
        case .standard: "ふつう"
        case .large: "大きめ"
        case .larger: "特大"
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
