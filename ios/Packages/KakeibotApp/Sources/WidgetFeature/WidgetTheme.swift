import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct WidgetTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let look: ThemeLook

    func body(content: Content) -> some View {
        let palette = look.palette(isDark: colorScheme == .dark)

        content
            .containerBackground(for: .widget) {
                Palette.background(of: palette)
            }
            .environment(\.palette, palette)
            .environment(\.colorScheme, palette.isLight ? .light : .dark)
    }
}

extension View {
    func widgetTheme(_ look: ThemeLook) -> some View {
        modifier(WidgetTheme(look: look))
    }
}
