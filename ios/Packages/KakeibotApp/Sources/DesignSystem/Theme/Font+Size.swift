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
