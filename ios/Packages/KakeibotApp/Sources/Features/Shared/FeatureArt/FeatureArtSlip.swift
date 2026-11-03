import Core
import DesignSystem
import SwiftUI

struct FeatureArtSlip: View {
    var showsRates = true
    var showsTotal = false
    var count = FeatureArtSample.items.count

    var body: some View {
        VStack(spacing: 6) {
            ForEach(FeatureArtSample.items.prefix(count), id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.name)
                        .foregroundStyle(Palette.text)
                        .fixedSize()

                    if showsRates {
                        EntryReceiptTaxRateBadge(rate: item.rate)
                    }

                    EntryReceiptLeader()

                    Text(AmountText.text(item.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                        .fixedSize()
                }
            }

            if showsTotal {
                EntryReceiptRule(style: .double)

                HStack(alignment: .firstTextBaseline) {
                    Text("合計")
                        .foregroundStyle(Palette.text)

                    Spacer(minLength: 4)

                    Text(AmountText.text(FeatureArtSample.total))
                        .displayFont(.small, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                }
            }
        }
        .textFont(size: .caption)
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 9 + Self.tooth / 2)
        .background {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.4), radius: 3, y: 1)
        }
        .overlay {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
    }
}

private extension FeatureArtSlip {
    static let tooth: CGFloat = 6
}
