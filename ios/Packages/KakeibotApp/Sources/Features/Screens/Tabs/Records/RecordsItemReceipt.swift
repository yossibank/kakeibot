import Core
import DesignSystem
import SwiftUI

struct RecordsItemReceipt: View {
    let items: [EntryItem]
    let amount: Int

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 6) {
                ForEach(items) { item in
                    itemLine(item)
                }
            }

            EntryReceiptRule(style: .dashed)

            if tax != 0 {
                summaryLine("消費税", amount: tax)
            }

            EntryReceiptRule(style: .double)

            HStack(alignment: .firstTextBaseline) {
                Text("合計")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Spacer()

                Text(AmountText.text(amount))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12 + Self.tooth / 2)
        .background {
            paper
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.4), radius: 6, y: 2)
        }
        .overlay {
            paper
                .stroke(Palette.hairline, lineWidth: 1)
        }
    }
}

private extension RecordsItemReceipt {
    static let tooth: CGFloat = 8
}

private extension RecordsItemReceipt {
    var tax: Int {
        EntryItemTotal(items.map(EntryItem.Draft.init)).taxes.reduce(0) { $0 + $1.amount }
    }

    var paper: EntryReceiptShape {
        EntryReceiptShape(tooth: Self.tooth, hasTopEdge: true)
    }
}

private extension RecordsItemReceipt {
    func itemLine(_ item: EntryItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(item.name)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            Text(AmountText.text(item.amount))
                .monospacedDigit()
                .foregroundStyle(Palette.text)

            if let rate = item.taxRate {
                Text("\(rate.rawValue)%")
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }
        }
        .textFont(.caption)
    }

    func summaryLine(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Palette.subtext)

            Spacer()

            Text(AmountText.text(amount))
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
        .textFont(.caption)
    }
}
