import Core
import DesignSystem
import SwiftUI

struct EntryReceiptTaxBreakdown: View {
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

private extension EntryReceiptTaxBreakdown {
    func grid(isCompact: Bool) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(taxes, id: \.rate) { tax in
                GridRow(alignment: .firstTextBaseline) {
                    EntryReceiptTaxRateBadge(rate: tax.rate)

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
