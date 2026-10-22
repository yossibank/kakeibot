import DesignSystem
import SwiftUI

struct SettingsShowZone: View {
    @Environment(\.themeStyle.corner) private var corner

    let isTargeted: Bool

    var body: some View {
        let color = isTargeted ? Palette.accent : Palette.subtext
        let labelHeight = isTargeted
            ? SettingsDropZones.labelHeight
            : CGFloat.infinity

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "eye")

                Text(title)
            }
            .contentTransition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: labelHeight)

            if isTargeted {
                Spacer(minLength: 0)
            }
        }
        .textFont(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    var title: String {
        isTargeted ? "離すと表示に戻ります" : "ここに置くと表示に戻ります"
    }
}
