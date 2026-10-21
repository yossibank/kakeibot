import Core
import SwiftUI

public extension Font {
    static func display(
        _ size: FontSize,
        weight: Weight = .regular,
        in font: ThemeFont,
        scale: Double
    ) -> Font {
        display(size: size.rawValue * scale, weight: weight, in: font)
    }

    static func display(
        size: CGFloat,
        weight: Weight = .regular,
        in font: ThemeFont
    ) -> Font {
        if let name = font.customName {
            return .custom(name, fixedSize: size)
        }

        let design: Design = font == .mincho ? .serif : .default
        return .system(size: size, weight: weight, design: design)
    }

    static func text(
        _ style: TextStyle,
        weight: Weight? = nil,
        in font: ThemeFont,
        scale: Double
    ) -> Font {
        let size = style.baseSize * scale
        let design: Design = font == .mincho ? .serif : .default
        let base: Font = font.customName.map { name in
            .custom(name, fixedSize: size)
        } ?? .system(size: size, design: design)

        guard let weight else {
            return base
        }

        return base.weight(weight)
    }

    static func text(
        size: FontSize,
        weight: Weight = .regular,
        in font: ThemeFont,
        scale: Double
    ) -> Font {
        display(size: size.rawValue * scale, weight: weight, in: font)
    }

    static func sans(
        _ size: FontSize,
        weight: Weight = .regular,
        scale: Double
    ) -> Font {
        .system(size: size.rawValue * scale, weight: weight)
    }
}

private extension ThemeFont {
    var customName: String? {
        switch self {
        case .mincho, .gothic: nil
        case .rounded: "HiraMaruProN-W4"
        case .handwriting: "KleeOne-Regular"
        case .dot: "DotGothic16-Regular"
        }
    }
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
