import SwiftUI

public extension View {
    func sansFont(
        _ size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(SansFont(size: size, weight: weight))
    }
}

private struct SansFont: ViewModifier {
    @Environment(\.themeStyle.textSize.scale) private var scale

    let size: FontSize
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.sans(size, weight: weight, scale: scale))
    }
}
