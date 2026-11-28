import Core

public extension ThemeStyle {
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

public extension ThemeTextSize {
    var title: String {
        switch self {
        case .small: "小さめ"
        case .standard: "ふつう"
        case .large: "大きめ"
        }
    }
}

public extension ThemeCorner {
    var title: String {
        switch self {
        case .square: "なし"
        case .small: "小さめ"
        case .standard: "ふつう"
        case .large: "大きめ"
        }
    }
}

public extension ThemeRowSpacing {
    var title: String {
        switch self {
        case .compact: "詰める"
        case .standard: "ふつう"
        case .relaxed: "ゆったり"
        }
    }
}

public extension ThemeStampShape {
    var title: String {
        switch self {
        case .circle: "丸"
        case .rounded: "角丸"
        case .seal: "印"
        }
    }
}

public extension ThemeBackdrop {
    var title: String {
        switch self {
        case .plain: "無地"
        case .ruled: "罫線"
        case .grid: "方眼"
        }
    }
}

public extension ThemeFont {
    var title: String {
        switch self {
        case .mincho: "明朝"
        case .gothic: "ゴシック"
        case .rounded: "丸ゴシック"
        case .handwriting: "手書き"
        case .dot: "ドット"
        case .pop: "ポップ"
        case .textbook: "教科書"
        case .boldMincho: "太明朝"
        case .boldGothic: "太ゴシック"
        case .kanaMincho: "かな明朝"
        }
    }
}
