import DesignSystem
import SwiftUI

struct SettingsShowZone: View {
    @Environment(\.themeStyle.corner) private var corner

    let isTargeted: Bool

    var body: some View {
        let color = isTargeted ? Palette.accent : Palette.subtext

        HStack(spacing: 8) {
            Image(systemName: "eye")

            Text("ここに置くと表示に戻ります")
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            shape
                .fill(Palette.backgroundBottom.opacity(.strong))

            shape
                .fill(fill)
        }
        .overlay {
            shape
                .stroke(color.opacity(0.6), style: .dashed)
        }
    }
}

private extension SettingsShowZone {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var fill: Color {
        isTargeted ? Palette.accent.opacity(.subtle) : Color.clear
    }
}
