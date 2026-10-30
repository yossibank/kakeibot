import Core
import SwiftUI

public enum FontSize: CGFloat, Sendable {
    case micro = 9
    case caption = 11
    case small = 13
    case body = 16
    case headline = 20
    case title = 28
    case largeTitle = 32
    case display = 40
}

public extension FontSize {
    static let minimumPoints: CGFloat = 10
}

public extension Font {
    static func display(
        _ size: FontSize,
        weight: Weight = .regular,
        in font: ThemeFont,
        scale: Double,
        shared: Double = 1
    ) -> Font {
        let points = points(size.rawValue, scale: scale, shared: shared)
        return display(size: points, weight: weight, in: font)
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
        scale: Double,
        shared: Double = 1
    ) -> Font {
        let size = points(style.baseSize, scale: scale, shared: shared)
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
        scale: Double,
        shared: Double = 1
    ) -> Font {
        display(
            size,
            weight: weight,
            in: font,
            scale: scale,
            shared: shared
        )
    }

    static func sans(
        _ size: FontSize,
        weight: Weight = .regular,
        scale: Double,
        shared: Double = 1
    ) -> Font {
        let points = points(size.rawValue, scale: scale, shared: shared)
        return .system(size: points, weight: weight)
    }

    static func points(
        _ base: CGFloat,
        scale: Double,
        shared: Double
    ) -> CGFloat {
        max(base * scale, FontSize.minimumPoints) * shared
    }
}

private extension ThemeFont {
    var customName: String? {
        switch self {
        case .mincho, .gothic: nil
        case .rounded: "HiraMaruProN-W4"
        case .handwriting: "KleeOne-Regular"
        case .dot: "DotGothic16-Regular"
        case .pop: "HachiMaruPop-Regular"
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
