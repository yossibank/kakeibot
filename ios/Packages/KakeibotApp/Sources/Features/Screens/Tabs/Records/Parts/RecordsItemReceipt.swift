import Core
import DesignSystem
import SwiftUI

struct RecordsItemReceipt: View {
    var taxIncluded = false
    var onClose: (() -> Void)?

    let items: [EntryItem]
    let amount: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("お買上明細")
                .textFont(.caption2, weight: .semibold)
                .tracking(3)
                .foregroundStyle(Palette.subtext)

            EntryReceiptRule(style: .dashed)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    itemLine(item)
                }
            }

            EntryReceiptRule(style: .dashed)

            if !totals.taxes.isEmpty {
                EntryReceiptTaxBreakdown(taxes: totals.taxes, taxIncluded: taxIncluded)
            }

            if adjustment != 0 {
                summaryLine("差額", amount: adjustment, color: Palette.amber)
            }

            EntryReceiptRule(style: .double)

            HStack(alignment: .firstTextBaseline) {
                Text("合計")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Text("\(itemCount)点")
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                Spacer()

                Text(AmountText.text(amount))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12 + Self.tooth / 2)
        .background {
            paper
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.4), radius: 6, y: 2)
        }
        .overlay {
            paper
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
        .contentShape(.rect)
        .onTapGesture {
            onClose?()
        }
    }
}

private extension RecordsItemReceipt {
    static let tooth: CGFloat = 8
}

private extension RecordsItemReceipt {
    var totals: EntryItemTotal {
        EntryItemTotal(items.map(EntryItem.Draft.init), taxIncluded: taxIncluded)
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var showsRates: Bool {
        Set(items.map(\.taxRate)).count > 1
    }

    var adjustment: Int {
        amount - totals.total
    }

    var paper: EntryReceiptShape {
        EntryReceiptShape(tooth: Self.tooth, hasTopEdge: true)
    }
}

private extension RecordsItemReceipt {
    func itemLine(_ item: EntryItem) -> some View {
        ViewThatFits(in: .horizontal) {
            itemLine(item, style: .caption, fitsName: true)

            itemLine(item, style: .caption2, fitsName: true)

            itemLine(item, style: .caption2, fitsName: false)
        }
    }

    func itemLine(
        _ item: EntryItem,
        style: Font.TextStyle,
        fitsName: Bool
    ) -> some View {
        let color = item.amount < 0 ? Palette.rose : Palette.text

        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(item.name)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: fitsName, vertical: false)
                .layoutPriority(1)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .fixedSize()
            }

            if showsRates, let rate = item.taxRate {
                EntryReceiptTaxRateBadge(rate: rate)
            }

            EntryReceiptLeader()

            Text(AmountText.text(item.amount))
                .monospacedDigit()
                .foregroundStyle(color)
                .fixedSize()
        }
        .textFont(style)
    }

    func summaryLine(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(AmountText.text(amount))
                .monospacedDigit()
        }
        .textFont(.caption)
        .foregroundStyle(color)
    }
}
