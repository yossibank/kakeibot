import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct WidgetTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let look: ThemeLook
    let style: ThemeStyle

    func body(content: Content) -> some View {
        let palette = look.palette(isDark: colorScheme == .dark)

        content
            .containerBackground(for: .widget) {
                Palette.background(of: palette)
            }
            .environment(\.palette, palette)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, palette.isLight ? .light : .dark)
    }
}

extension View {
    func widgetTheme(
        _ look: ThemeLook,
        style: ThemeStyle
    ) -> some View {
        modifier(WidgetTheme(look: look, style: style))
    }
}
