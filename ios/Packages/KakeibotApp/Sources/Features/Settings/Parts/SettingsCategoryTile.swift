import Core
import DesignSystem
import SwiftUI

struct SettingsCategoryTile: View {
    @Environment(\.themeStyle.corner) private var corner

    let category: EntryCategory
    let icon: Icon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = isSelected ? Palette.accentStrong : Palette.subtext

        Button(action: action) {
            VStack(spacing: 4) {
                IconImage(icon, size: 17)

                Text(category.name)
                    .textFont(size: .caption)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                SettingsTile.fill(isSelected: isSelected),
                in: .rect(cornerRadius: corner.radius(12))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(12))
                    .stroke(
                        SettingsTile.stroke(isSelected: isSelected),
                        lineWidth: 1
                    )
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
