import Core
import SwiftUI

public extension View {
    func displayFont(
        _ size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(ThemeFontModifier(role: .display, spec: .size(size, weight)))
    }

    func displayFont(
        style: Font.TextStyle,
        weight: Font.Weight? = nil
    ) -> some View {
        modifier(ThemeFontModifier(role: .display, spec: .style(style, weight)))
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
        modifier(ThemeFontModifier(role: .text, spec: .style(style, weight)))
    }

    func textFont(
        size: FontSize,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(ThemeFontModifier(role: .text, spec: .size(size, weight)))
    }
}

private struct ThemeFontModifier: ViewModifier {
    @Environment(\.themeStyle.displayFont) private var displayFont
    @Environment(\.themeStyle.textFont) private var textFont
    @Environment(\.themeStyle.textSize.scale) private var textSize
    @Environment(\.sharedTextScale) private var shared

    let role: Role
    let spec: Spec

    func body(content: Content) -> some View {
        let font = role == .display ? displayFont : textFont
        return content.font(spec.font(in: font, scale: textSize, shared: shared))
    }
}

private struct SansFont: ViewModifier {
    @Environment(\.themeStyle.textSize.scale) private var textSize
    @Environment(\.sharedTextScale) private var shared

    let size: FontSize
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.sans(size, weight: weight, scale: textSize, shared: shared))
    }
}

private extension ThemeFontModifier {
    enum Role {
        case display
        case text
    }

    enum Spec {
        case style(Font.TextStyle, Font.Weight?)
        case size(FontSize, Font.Weight)
    }
}

private extension ThemeFontModifier.Spec {
    func font(
        in font: ThemeFont,
        scale: Double,
        shared: Double
    ) -> Font {
        switch self {
        case let .style(style, weight):
            .text(
                style,
                weight: weight,
                in: font,
                scale: scale,
                shared: shared
            )

        case let .size(size, weight):
            .display(
                size,
                weight: weight,
                in: font,
                scale: scale,
                shared: shared
            )
        }
    }
}
