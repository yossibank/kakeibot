import DesignSystem
import SwiftUI

struct SettingsHideZone: View {
    let isTargeted: Bool
    let height: CGFloat

    var body: some View {
        let color = isTargeted ? Palette.rose : Palette.mist

        HStack(spacing: 8) {
            Image(systemName: "eye.slash")

            Text("ここに置くと非表示になります")
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: height)
        .background(fill, in: Self.shape)
        .overlay {
            Self.shape
                .stroke(color.opacity(0.6), style: Self.dash)
        }
    }
}

private extension SettingsHideZone {
    static let shape = RoundedRectangle(cornerRadius: 16)
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    var fill: Color {
        isTargeted ? Palette.rose.opacity(0.12) : Color.clear
    }
}
