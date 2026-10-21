import DesignSystem
import SwiftUI

struct EntryFilterLine: View {
    let title: String
    let onOpen: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.accent)

            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            Spacer()

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Palette.hint)
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .background(Palette.accent.opacity(.subtle), in: Capsule())
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .transition(.opacity)
    }
}
