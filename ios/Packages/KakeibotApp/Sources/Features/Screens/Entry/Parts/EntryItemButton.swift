import Core
import DesignSystem
import SwiftUI

struct EntryItemButton: View {
    let count: Int
    let total: Int
    let adjustment: Int
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 4) {
                Image(systemName: "receipt")
                    .foregroundStyle(Palette.accent)

                Text("品目 \(count)件")
                    .foregroundStyle(Palette.accentStrong)

                Text(AmountText.text(total))
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)

                if adjustment != 0 {
                    Text("差額 \(AmountText.text(adjustment))")
                        .monospacedDigit()
                        .foregroundStyle(Palette.amber)
                }

                Image(systemName: "chevron.right")
                    .textFont(.caption2, weight: .semibold)
                    .foregroundStyle(Palette.hint)
            }
            .textFont(.caption, weight: .semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 12)
            .frame(height: Self.height)
            .background(fill, in: .capsule)
            .contentShape(.capsule)
            .tapArea(Self.tapOutsets)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryItemButton {
    static let height: CGFloat = 28

    static let tapOutsets = EdgeInsets(
        top: 8,
        leading: 0,
        bottom: 8,
        trailing: 0
    )

    var fill: Color {
        adjustment == 0 ? Palette.accent.opacity(.subtle) : Palette.amber.opacity(.subtle)
    }
}

#Preview {
    VStack(spacing: 16) {
        EntryItemButton(count: 4, total: 1674, adjustment: 0) {}

        EntryItemButton(count: 4, total: 1674, adjustment: -1008) {}
    }
    .padding()
    .background(Palette.background)
}
