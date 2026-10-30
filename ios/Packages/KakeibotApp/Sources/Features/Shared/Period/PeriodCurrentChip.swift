import DesignSystem
import SwiftUI

struct PeriodCurrentChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textFont(.caption, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .frame(minHeight: 24)
                .background(Palette.accent.opacity(.subtle), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 0.8)
                }
                .tapArea(Self.tapOutsets)
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }
}

private extension PeriodCurrentChip {
    static let tapOutsets = EdgeInsets(
        top: 10,
        leading: 4,
        bottom: 10,
        trailing: 4
    )
}
