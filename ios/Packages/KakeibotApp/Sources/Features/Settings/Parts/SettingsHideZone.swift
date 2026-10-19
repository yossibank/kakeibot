import DesignSystem
import SwiftUI

struct SettingsHideZone: View {
    let isTargeted: Bool
    let height: CGFloat
    var title = "ここに置くと非表示になります"
    var systemImage = "eye.slash"

    var body: some View {
        let color = isTargeted ? Palette.rose : Palette.mist

        HStack(spacing: 8) {
            Image(systemName: systemImage)

            Text(title)
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: height)
        .background(fill, in: Self.shape)
        .overlay {
            Self.shape
                .stroke(color.opacity(0.6), style: .dashed)
        }
    }
}

private extension SettingsHideZone {
    static let shape = RoundedRectangle(cornerRadius: 16)
    var fill: Color {
        isTargeted ? Palette.rose.opacity(.subtle) : Color.clear
    }
}
