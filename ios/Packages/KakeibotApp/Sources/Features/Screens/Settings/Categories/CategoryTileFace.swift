import Core
import DesignSystem
import SwiftUI

struct CategoryTileFace: View {
    let icon: Icon?
    let name: String
    let isHidden: Bool

    var body: some View {
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.subtext
        let opacity: Double = isHidden ? 0.6 : 1

        VStack(spacing: 8) {
            IconImage(icon, size: 20)
                .foregroundStyle(Palette.accent)

            Text(name)
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)
                .sharedTextScale()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(color)
                .frame(width: 24, height: 2)
                .padding(.bottom, 8)
        }
        .settingsTileFace(isHidden: isHidden)
        .opacity(opacity)
    }
}
