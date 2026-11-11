import Core
import DesignSystem
import SwiftUI

struct CategoryTileFace: View {
    let icon: Icon?
    let name: String
    let isHidden: Bool

    var body: some View {
        let opacity: Double = isHidden ? 0.6 : 1

        VStack(spacing: 8) {
            IconBadge(icon, size: 40)

            Text(name)
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(TextScale.floor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .settingsTileFace(isHidden: isHidden)
        .opacity(opacity)
    }
}
