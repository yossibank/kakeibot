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
            .foregroundStyle(Palette.accentStrong)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Palette.accent.opacity(.subtle), in: .capsule)
    }
}

struct EntryTaxBreakdown: View {
    let taxes: [EntryItemTotal.Tax]
    let taxIncluded: Bool

    var body: some View {
        VStack(spacing: 6) {
            ForEach(taxes, id: \.rate) { tax in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    EntryTaxRateBadge(rate: tax.rate)

                    Text("対象")

                    Text(AmountText.text(tax.base))
                        .monospacedDigit()

                    Spacer(minLength: 8)

                    Text(taxIncluded ? "うち消費税" : "消費税")

                    Text(AmountText.text(tax.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                }
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
    }
}
