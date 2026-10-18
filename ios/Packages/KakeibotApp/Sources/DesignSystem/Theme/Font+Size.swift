import SwiftUI

public extension Font {
    static func serif(
        _ size: FontSize,
        weight: Weight = .regular
    ) -> Font {
        .system(size: size.rawValue, weight: weight, design: .serif)
    }

    static func sans(
        _ size: FontSize,
        weight: Weight = .regular
    ) -> Font {
        .system(size: size.rawValue, weight: weight)
    }
}
