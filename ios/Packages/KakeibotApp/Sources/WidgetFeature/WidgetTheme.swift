import Core
import DesignSystem
import SwiftUI

struct WidgetTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let look: ThemeLook

    func body(content: Content) -> some View {
        let palette = look.palette(isDark: colorScheme == .dark)

        content
            .environment(\.palette, palette)
            .environment(\.colorScheme, palette.isLight ? .light : .dark)
    }
}

extension View {
    func widgetTheme(_ look: ThemeLook) -> some View {
        modifier(WidgetTheme(look: look))
    }
}
