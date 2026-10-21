import Core
import DesignSystem
import SwiftUI

struct LaunchScreenOption: View {
    @Environment(\.themeStyle.corner) private var corner

    let screen: LaunchScreen
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let mark = isSelected ? "checkmark.circle.fill" : "circle"

        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: screen.systemImage)
                    .sansFont(.headline, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(screen.title)
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)

                    Text(screen.note)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }

                Spacer()

                Image(systemName: mark)
                    .sansFont(.headline)
                    .foregroundStyle(Palette.accent)
            }
            .padding(16)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(stroke, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension LaunchScreenOption {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }
}
