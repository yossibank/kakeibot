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
            HStack(spacing: 8) {
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
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.bottom, Self.tooth / 2)
            .frame(height: Self.height)
            .background {
                paper
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.5), radius: 3, y: 1)
            }
            .overlay {
                paper
                    .stroke(
                        adjustment == 0 ? Palette.outline : Palette.amber.opacity(.medium),
                        lineWidth: 1
                    )
            }
            .contentShape(.rect)
            .tapArea(Self.tapOutsets)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryItemButton {
    static let height: CGFloat = 36
    static let tooth: CGFloat = 6

    static let tapOutsets = EdgeInsets(
        top: 4,
        leading: 0,
        bottom: 4,
        trailing: 0
    )

    var paper: EntryReceiptShape {
        EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
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
