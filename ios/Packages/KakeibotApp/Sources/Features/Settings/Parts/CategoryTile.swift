import Core
import DesignSystem
import SwiftUI

struct CategoryTile: View {
    let category: EntryCategory
    let icon: Icon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = isSelected ? Palette.champagne : Palette.mist

        Button(action: action) {
            VStack(spacing: 4) {
                IconImage(icon, size: 17)

                Text(category.name)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                SettingsTile.fill(isSelected: isSelected),
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
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
