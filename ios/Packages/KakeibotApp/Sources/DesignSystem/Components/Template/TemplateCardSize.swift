import Core
import SwiftUI

public enum TemplateCardSize: Sendable {
    case regular
    case large
}

public extension TemplateCardSize {
    var textSpacing: CGFloat {
        switch self {
        case .regular: 3
        case .large: 10
        }
    }

    var height: CGFloat {
        switch self {
        case .regular: 116
        case .large: 172
        }
    }

    func nameFont(in style: ThemeStyle) -> Font {
        let size: FontSize = self == .regular ? .body : .headline
        return display(size, weight: .medium, in: style)
    }

    func amountFont(in style: ThemeStyle) -> Font {
        let size: FontSize = self == .regular ? .headline : .largeTitle
        return display(size, weight: .medium, in: style)
    }

    func emptyAmountFont(in style: ThemeStyle) -> Font {
        let size: FontSize = self == .regular ? .small : .body
        return display(size, weight: .regular, in: style)
    }
}

extension TemplateCardSize {
    var nameLines: Int {
        switch self {
        case .regular: 2
        case .large: 1
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular: 16
        case .large: 24
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .regular: 34
        case .large: 52
        }
    }

    var gap: CGFloat {
        switch self {
        case .regular: 10
        case .large: 14
        }
    }

    var spacing: CGFloat {
        switch self {
        case .regular: 10
        case .large: 16
        }
    }

    var padding: CGFloat {
        switch self {
        case .regular: 14
        case .large: 22
        }
    }

    var amountHeight: CGFloat {
        switch self {
        case .regular: 26
        case .large: 42
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular: 20
        case .large: 26
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .regular: 12
        case .large: 24
        }
    }

    func detailFont(in style: ThemeStyle) -> Font {
        let font = style.textFont
        let scale = style.textSize.scale

        switch self {
        case .regular: return .text(size: .caption, in: font, scale: scale)
        case .large: return .text(.caption, in: font, scale: scale)
        }
    }
}

private extension TemplateCardSize {
    func display(
        _ size: FontSize,
        weight: Font.Weight,
        in style: ThemeStyle
    ) -> Font {
        .display(
            size,
            weight: weight,
            in: style.displayFont,
            scale: style.textSize.scale
        )
    }
}
