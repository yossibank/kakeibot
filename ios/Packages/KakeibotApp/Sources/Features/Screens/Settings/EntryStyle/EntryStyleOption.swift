import Core
import DesignSystem
import SwiftUI

struct EntryStyleOption: View {
    @Environment(\.themeStyle.corner) private var corner

    let style: EntryStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let mark = isSelected ? "checkmark.circle.fill" : "circle"
        let opacity = style.isReady ? 1 : 0.5

        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: style.systemImage)
                    .sansFont(.headline, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title)
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)

                    Text(style.note)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }

                Spacer()

                if style.isReady {
                    Image(systemName: mark)
                        .sansFont(.headline)
                        .foregroundStyle(Palette.accent)
                } else {
                    Text("準備中")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay {
                            Capsule()
                                .stroke(Palette.line, lineWidth: 1)
                        }
                }
            }
            .padding(16)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(stroke, lineWidth: 1)
            }
            .contentShape(.rect)
            .opacity(opacity)
        }
        .buttonStyle(.plain)
        .disabled(!style.isReady)
    }
}

private extension EntryStyleOption {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }
}
