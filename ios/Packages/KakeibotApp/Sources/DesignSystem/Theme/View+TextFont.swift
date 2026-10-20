import Core
import SwiftUI

public extension View {
    func textFont(
        _ style: Font.TextStyle,
        weight: Font.Weight? = nil
    ) -> some View {
        modifier(TextFont(spec: .style(style, weight)))
    }

    func textFont(
        size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(TextFont(spec: .size(size, weight)))
    }
}

private struct TextFont: ViewModifier {
    @Environment(\.themeStyle.textFont) private var font

    let spec: Spec

    func body(content: Content) -> some View {
        content.font(spec.font(in: font))
    }
}

private extension TextFont {
    enum Spec {
        case style(Font.TextStyle, Font.Weight?)
        case size(FontSize, Font.Weight)
    }
}

private extension TextFont.Spec {
    func font(in font: ThemeFont) -> Font {
        switch self {
        case let .style(style, weight):
            .text(style, weight: weight, in: font)
        case let .size(size, weight):
            .text(size: size, weight: weight, in: font)
        }
    }
}
