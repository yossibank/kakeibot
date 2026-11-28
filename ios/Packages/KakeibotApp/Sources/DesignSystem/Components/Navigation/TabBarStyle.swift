import SwiftUI

enum TabBarStyle {
    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.07), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    static var rim: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.strong),
                Palette.accent.opacity(.muted)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var indicatorRim: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accentStrong.opacity(.strong),
                Palette.accent.opacity(.soft)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldRing: AngularGradient {
        AngularGradient(
            colors: [
                Palette.goldLight,
                Palette.goldFace,
                Palette.goldShade,
                Palette.goldFace,
                Palette.goldLight
            ],
            center: .center
        )
    }

    static func ring(hasDecorations: Bool) -> AnyShapeStyle {
        if hasDecorations {
            return AnyShapeStyle(goldRing)
        }

        return AnyShapeStyle(Palette.outline)
    }
}
