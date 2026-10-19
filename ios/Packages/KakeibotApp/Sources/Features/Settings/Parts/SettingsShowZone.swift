import DesignSystem
import SwiftUI

struct SettingsShowZone: View {
    let isTargeted: Bool

    var body: some View {
        let color = isTargeted ? Palette.gold : Palette.mist

        HStack(spacing: 8) {
            Image(systemName: "eye")

            Text("ここに置くと表示に戻ります")
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Self.shape
                .fill(Palette.nightBottom.opacity(.strong))

            Self.shape
                .fill(fill)
        }
        .overlay {
            Self.shape
                .stroke(color.opacity(0.6), style: .dashed)
        }
    }
}

private extension SettingsShowZone {
    static let shape = RoundedRectangle(cornerRadius: 16)

    var fill: Color {
        isTargeted ? Palette.gold.opacity(.subtle) : Color.clear
    }
}
