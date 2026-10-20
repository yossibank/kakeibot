import Core
import DesignSystem
import SwiftUI

struct SettingsWalletTile: View {
    let wallet: Wallet
    let icon: Icon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = isSelected ? Palette.accentStrong : Palette.subtext

        Button(action: action) {
            HStack(spacing: 6) {
                IconImage(icon, size: 13)

                Text(wallet.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                SettingsTile.fill(isSelected: isSelected),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        SettingsTile.stroke(isSelected: isSelected),
                        lineWidth: 1
                    )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
