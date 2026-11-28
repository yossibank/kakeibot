import Core
import SwiftUI

public extension View {
    func themeStyle(_ style: ThemeStyle) -> some View {
        modifier(ThemeStyleApplying(style: style))
    }
}

private struct ThemeStyleApplying: ViewModifier {
    let style: ThemeStyle

    func body(content: Content) -> some View {
        let loader = ThemeFontLoader.shared
        let fonts = [style.displayFont, style.textFont]

        var shown = style
        shown.displayFont = loader.shownFont(for: style.displayFont)
        shown.textFont = loader.shownFont(for: style.textFont)

        return content
            .environment(\.themeStyle, shown)
            .font(shown.bodyFont)
            .onChange(of: fonts, initial: true) { _, fonts in
                for font in fonts {
                    loader.load(font)
                }

                loader.restore(ThemeFont.allCases)
            }
    }
}
