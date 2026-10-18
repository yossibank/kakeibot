import DesignSystem
import SwiftUI

struct SettingsChoice: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        let color = isSelected ? Palette.champagne : Palette.mist

        Button(action: action) {
            Text(title)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(color)
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
