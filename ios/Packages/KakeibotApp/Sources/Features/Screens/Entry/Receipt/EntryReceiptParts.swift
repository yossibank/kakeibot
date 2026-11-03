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
            .frame(minWidth: 8, maxWidth: .infinity)
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
        ViewThatFits(in: .horizontal) {
            grid(isCompact: false)

            grid(isCompact: true)
        }
        .textFont(.caption)
        .foregroundStyle(Palette.subtext)
    }
}

private extension EntryTaxBreakdown {
    func grid(isCompact: Bool) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(taxes, id: \.rate) { tax in
                GridRow(alignment: .firstTextBaseline) {
                    EntryTaxRateBadge(rate: tax.rate)

                    if !isCompact {
                        Text("対象")
                            .fixedSize()
                    }

                    Text(AmountText.text(tax.base))
                        .monospacedDigit()
                        .fixedSize()
                        .gridColumnAlignment(.trailing)

                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: 0)

                    Text(taxTitle(isCompact: isCompact))
                        .fixedSize()
                        .gridColumnAlignment(.trailing)

                    Text(AmountText.text(tax.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                        .fixedSize()
                        .gridColumnAlignment(.trailing)
                }
            }
        }
    }

    func taxTitle(isCompact: Bool) -> String {
        switch (taxIncluded, isCompact) {
        case (true, false): "うち消費税"
        case (true, true): "うち税"
        case (false, false): "消費税"
        case (false, true): "税"
        }
    }
}
