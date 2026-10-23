import Core
import SwiftUI

public extension View {
    func displayFont(
        _ size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func sansFont(
        _ size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(SansFont(size: size, weight: weight))
    }

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

private struct DisplayFont: ViewModifier {
    @Environment(\.themeStyle.displayFont) private var font
    @Environment(\.themeStyle.textSize.scale) private var scale

    let size: FontSize
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.display(size, weight: weight, in: font, scale: scale))
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

private struct TextFont: ViewModifier {
    @Environment(\.themeStyle.textFont) private var font
    @Environment(\.themeStyle.textSize.scale) private var scale

    let spec: Spec

    func body(content: Content) -> some View {
        content.font(spec.font(in: font, scale: scale))
    }
}

private extension TextFont {
    enum Spec {
        case style(Font.TextStyle, Font.Weight?)
        case size(FontSize, Font.Weight)
    }
}

private extension TextFont.Spec {
    func font(
        in font: ThemeFont,
        scale: Double
    ) -> Font {
        switch self {
        case let .style(style, weight):
            .text(style, weight: weight, in: font, scale: scale)
        case let .size(size, weight):
            .text(size: size, weight: weight, in: font, scale: scale)
        }
    }
}
