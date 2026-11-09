import Core
import DesignSystem
import SwiftUI

struct BillTabs: View {
    @Environment(\.themeStyle.corner) private var corner

    let pages: [BillPage]
    let current: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pages.enumerated()), id: \.element.month) { index, page in
                Button {
                    if index != current {
                        onSelect(index)
                    }
                } label: {
                    tab(page, isSelected: index == current)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }
}

private extension BillTabs {
    static var selectedFace: LinearGradient {
        LinearGradient(
            colors: [Palette.accent, Palette.accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func tab(
        _ page: BillPage,
        isSelected: Bool
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16), style: .continuous)
        let label = isSelected ? Palette.backgroundBottom : Palette.text
        let note = isSelected ? Palette.backgroundBottom.opacity(.strong) : Palette.subtext

        return VStack(alignment: .leading, spacing: 2) {
            Text(BillText.page(page.month))
                .textFont(.caption, weight: .semibold)
                .foregroundStyle(note)

            AmountText(
                page.total,
                font: .size(.headline, weight: .bold),
                color: label
            )
            .minimumScaleFactor(0.5)

            Text(BillText.count(of: page))
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(note)
                .minimumScaleFactor(0.8)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                shape
                    .fill(Self.selectedFace)
                    .glow(Palette.glow.opacity(.muted), radius: 8, y: 4)
            } else {
                shape
                    .fill(Palette.panel)
                    .overlay {
                        shape
                            .strokeBorder(Palette.line, lineWidth: 1)
                    }
            }
        }
        .contentShape(shape)
    }
}
