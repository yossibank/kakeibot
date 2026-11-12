import DesignSystem
import SwiftUI

struct EntryVoiceNotice: View {
    @Environment(\.themeStyle.corner) private var corner

    let notice: EntryVoiceFlow.Notice
    let onUndo: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notice.canUndo ? "checkmark.circle" : "exclamationmark.circle")
                .sansFont(.body)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(notice.title)
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(notice.canUndo ? Palette.accentStrong : Palette.text)

                if let message = notice.message {
                    Text(message)
                        .textFont(.caption)
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let hint = notice.hint {
                    Text(hint)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if notice.canUndo {
                ChipButton("取り消す", action: onUndo)
            }
        }
        .padding(12)
        .background(Palette.panel, in: shape)
        .background(tint.opacity(.subtle), in: shape)
        .overlay {
            shape
                .stroke(tint.opacity(.medium), lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(0.4), radius: 12, y: 6)
        .contentShape(shape)
        .onTapGesture(perform: onClose)
    }
}

private extension EntryVoiceNotice {
    var tint: Color {
        notice.canUndo ? Palette.accent : Palette.rose
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}
