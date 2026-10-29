import Core

extension ThemeStyle {
    var textTitle: String {
        let fonts = displayFont == textFont
            ? displayFont.title
            : "\(displayFont.title)と\(textFont.title)"

        guard textSize == .standard else {
            return "文字\(textSize.title)・\(fonts)"
        }

        return fonts
    }

    var shortTextTitle: String {
        guard textSize == .standard else {
            return "文字\(textSize.title)"
        }

        return textTitle
    }

    var lookTitle: String {
        "角\(corner.title)"
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

extension ThemeRowSpacing {
    var title: String {
        switch self {
        case .compact: "詰める"
        case .standard: "ふつう"
        case .relaxed: "ゆったり"
        }
    }
}

extension ThemeStampShape {
    var title: String {
        switch self {
        case .circle: "丸"
        case .rounded: "角丸"
        case .seal: "印"
        }
    }
}

extension ThemeBackdrop {
    var title: String {
        switch self {
        case .plain: "無地"
        case .washi: "和紙"
        case .grid: "方眼"
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
        case .pop: "ポップ"
        }
    }
}
