import Core
import DesignSystem
import SwiftUI

struct SettingsWalletTile: View {
    @Environment(\.themeStyle.corner) private var corner

    let wallet: Wallet
    let icon: Icon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = isSelected ? Palette.accentStrong : Palette.subtext

        Button(action: action) {
            VStack(spacing: 4) {
                IconImage(icon, size: 15)

                Text(wallet.name)
                    .textFont(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 68, maxHeight: .infinity)
            .background(
                SettingsTile.fill(isSelected: isSelected),
                in: .rect(cornerRadius: corner.radius(12))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(12))
                    .stroke(SettingsTile.stroke(isSelected: isSelected), lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
