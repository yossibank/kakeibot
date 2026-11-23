import Core
import DesignSystem
import SwiftUI

struct WalletRowIcon: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?

    var strokeWidth: CGFloat = IconBadge.lineWidth

    var body: some View {
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.subtext

        IconImage(icon, size: 22)
            .foregroundStyle(Palette.accent)
            .frame(width: 48, height: 48)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(12), style: .continuous)
                    .strokeBorder(color, lineWidth: strokeWidth)
            }
    }
}
