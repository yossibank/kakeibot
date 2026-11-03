import DesignSystem
import SwiftUI

struct ProOfferCard: View {
    @State var model: ProPurchaseModel

    let feature: String
    let onUnlock: () -> Void
    let onLearnMore: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ProMark()

                Text("\(feature)は Pro で使えます")
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            CardButton(model.purchaseTitle, style: .filled) {
                purchase()
            }
            .disabled(model.isWorking)

            HStack(spacing: 12) {
                CardButton("Pro について", style: .outlined(Palette.accent), action: onLearnMore)
                CardButton("あとで", style: .outlined(Palette.subtext), action: onCancel)
            }
        }
        .padding(16)
        .floatingCard()
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .task {
            await model.load()
        }
    }
}

private extension ProOfferCard {
    func purchase() {
        Task {
            if await model.purchase() {
                onUnlock()
            }
        }
    }
}

#Preview {
    ProOfferCard(
        model: ProPurchaseModel(store: .unavailable),
        feature: "手書きの字体",
        onUnlock: {},
        onLearnMore: {},
        onCancel: {}
    )
    .padding()
    .background(Palette.background)
}
