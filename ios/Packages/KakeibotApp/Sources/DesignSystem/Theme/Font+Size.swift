import Core
import SwiftUI

public extension Font {
    static func display(
        _ size: FontSize,
        weight: Weight = .regular,
        in font: ThemeFont
    ) -> Font {
        display(size: size.rawValue, weight: weight, in: font)
    }

    static func display(
        size: CGFloat,
        weight: Weight = .regular,
        in font: ThemeFont
    ) -> Font {
        switch font {
        case .mincho:
            .system(size: size, weight: weight, design: .serif)
        case .gothic:
            .system(size: size, weight: weight)
        case .rounded:
            .custom(roundedName, fixedSize: size)
        }
    }

    static func text(
        _ style: TextStyle,
        weight: Weight? = nil,
        in font: ThemeFont
    ) -> Font {
        let base: Font =
            switch font {
            case .mincho:
                .system(style, design: .serif)
            case .gothic:
                .system(style)
            case .rounded:
                .custom(roundedName, size: style.baseSize, relativeTo: style)
            }

        guard let weight else {
            return base
        }

        return base.weight(weight)
    }

    static func text(
        size: FontSize,
        weight: Weight = .regular,
        in font: ThemeFont
    ) -> Font {
        display(size: size.rawValue, weight: weight, in: font)
    }

    static func sans(
        _ size: FontSize,
        weight: Weight = .regular
    ) -> Font {
        .system(size: size.rawValue, weight: weight)
    }
}

private extension Font {
    static let roundedName = "HiraMaruProN-W4"
}

private extension Font.TextStyle {
    var baseSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}
