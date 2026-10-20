import SwiftUI

public extension View {
    func displayFont(
        _ size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }
}

private struct DisplayFont: ViewModifier {
    @Environment(\.themeStyle.font) private var font

    let size: FontSize
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.display(size, weight: weight, in: font))
    }
}
