import Core
import DesignSystem
import SwiftUI

struct WhatsNewReceiptScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .button:
            EntryReceiptButton(freeLeft: nil) {}
                .whatsNewTapped()

        case .camera:
            FeatureArtReceipt(showsViewfinder: true)
                .scaleEffect(0.95)

        case .items:
            VStack(spacing: 8) {
                FeatureArtSlip(showsRates: false)

                countBadge
            }
            .padding(.horizontal, 4)
        }
    }
}

extension WhatsNewReceiptScene {
    enum Step: Hashable, Sendable {
        case button
        case camera
        case items
    }
}

private extension WhatsNewReceiptScene {
    var countBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "receipt")

            Text("品目 \(FeatureArtSample.items.count)件")

            AmountText(FeatureArtSample.total, font: .size(.caption, weight: .semibold))
        }
        .textFont(size: .caption, weight: .semibold)
        .foregroundStyle(Palette.accentStrong)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Palette.lit.opacity(.subtle), in: .capsule)
    }
}
