import SwiftUI

public extension View {
    func glow(
        _ color: Color,
        radius: CGFloat,
        y: CGFloat = 0
    ) -> some View {
        modifier(
            Glow(
                color: color,
                radius: radius,
                y: y
            )
        )
    }
}

private struct Glow: ViewModifier {
    @Environment(\.themeStyle.decorations) private var isOn

    let color: Color
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        let shown = isOn ? color : .clear

        content
            .shadow(color: shown, radius: radius, y: y)
    }
}
