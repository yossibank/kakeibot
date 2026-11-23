import Core
import DesignSystem
import SwiftUI

struct WhatsNewItemsScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .add:
            Label("品目", systemImage: "plus")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .overlay {
                    Capsule()
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .whatsNewTapped()

        case .slip:
            itemForm

        case .list:
            FeatureArtSlip(showsRates: true, count: 2)
                .padding(.horizontal, 2)
        }
    }
}

extension WhatsNewItemsScene {
    enum Step: Hashable, Sendable {
        case add
        case slip
        case list
    }
}

private extension WhatsNewItemsScene {
    var itemForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("品名")
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)

            Text("牛乳")
                .textFont(size: .small, weight: .semibold)
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Palette.card, in: .rect(cornerRadius: 4))

            HStack(spacing: 4) {
                AmountText(198, font: .size(.caption, weight: .medium))

                Text("×")
                    .foregroundStyle(Palette.hint)

                Text("2")

                Text("=")
                    .foregroundStyle(Palette.hint)

                AmountText(396, font: .size(.caption, weight: .medium), color: Palette.accentStrong)
                    .bold()
            }
            .textFont(size: .caption, weight: .medium)
            .monospacedDigit()
            .foregroundStyle(Palette.text)
        }
        .padding(8)
        .background {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .fill(Palette.paper)
        }
        .overlay {
            EntryReceiptShape(tooth: 6, hasTopEdge: true, hasBottomEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
        .padding(.horizontal, 4)
    }
}
