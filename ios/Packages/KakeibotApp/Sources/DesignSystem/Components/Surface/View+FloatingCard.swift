import Core
import SwiftUI

public extension View {
    func floatingCard() -> some View {
        modifier(FloatingCardBackground())
    }
}

private struct FloatingCardBackground: ViewModifier {
    @Environment(\.themeStyle.corner) private var corner

    func body(content: Content) -> some View {
        content
            .background(Palette.panel, in: .rect(cornerRadius: corner.radius(20)))
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(20))
                    .stroke(Palette.outline, lineWidth: 1)
            }
            .shadow(color: Palette.shadow.opacity(0.45), radius: 20, y: 10)
    }
}
