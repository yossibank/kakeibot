import Core
import DesignSystem
import SwiftUI

struct EntryReceiptLeader: View {
    var body: some View {
        EntryRuleShape()
            .stroke(
                Palette.hint.opacity(0.8),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, 4])
            )
            .frame(minWidth: 12, maxWidth: .infinity)
            .frame(height: 2)
            .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[.bottom] + 3
            }
    }
}

struct EntryTaxRateBadge: View {
    let rate: EntryItem.TaxRate

    var body: some View {
        Text("\(rate.rawValue)%")
            .textFont(.caption2, weight: .semibold)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Palette.accentStrong)
            .padding(.horizontal, 6)
            .frame(minWidth: Self.minWidth)
            .padding(.vertical, 1)
            .background(Palette.accent.opacity(.subtle), in: .capsule)
    }
}

private extension EntryTaxRateBadge {
    static let minWidth: CGFloat = 44
}

struct EntryTaxBreakdown: View {
    let taxes: [EntryItemTotal.Tax]
    let taxIncluded: Bool

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(taxes, id: \.rate) { tax in
                GridRow(alignment: .firstTextBaseline) {
                    EntryTaxRateBadge(rate: tax.rate)

                    Text("対象")

                    Text(AmountText.text(tax.base))
                        .monospacedDigit()
                        .gridColumnAlignment(.trailing)

                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: 0)

                    Text(taxIncluded ? "うち消費税" : "消費税")
                        .gridColumnAlignment(.trailing)

                    Text(AmountText.text(tax.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                        .gridColumnAlignment(.trailing)
                }
            }
        }
        .textFont(.caption)
        .foregroundStyle(Palette.subtext)
        .lineLimit(1)
    }
}
