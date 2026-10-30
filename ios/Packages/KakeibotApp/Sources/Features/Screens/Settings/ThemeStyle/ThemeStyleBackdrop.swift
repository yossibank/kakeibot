import Core
import DesignSystem
import SwiftUI

struct ThemeStyleBackdrop: View {
    @Environment(\.themeStyle.corner) private var corner

    let backdrop: ThemeBackdrop

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))

        Backdrop()
            .overlay {
                card
            }
            .environment(\.themeStyle.backdrop, backdrop)
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .clipShape(shape)
            .overlay {
                shape
                    .strokeBorder(Palette.line, lineWidth: 1)
            }
    }
}

private extension ThemeStyleBackdrop {
    static let height: CGFloat = 112

    var card: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(Palette.accent.opacity(.medium))
                .frame(width: 32, height: 4)

            Capsule()
                .fill(Palette.subtext.opacity(.muted))
                .frame(height: 4)

            Capsule()
                .fill(Palette.subtext.opacity(.muted))
                .frame(width: 40, height: 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 12)
        .padding(.horizontal, 12)
    }
}
