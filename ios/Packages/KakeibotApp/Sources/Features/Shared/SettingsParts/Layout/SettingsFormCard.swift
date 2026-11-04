import DesignSystem
import SwiftUI

struct SettingsFormCard<Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        spacing: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(20))

        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(16)
        .background(SettingsTile.cardFill.opacity(0.7), in: shape)
        .overlay {
            shape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }
}
