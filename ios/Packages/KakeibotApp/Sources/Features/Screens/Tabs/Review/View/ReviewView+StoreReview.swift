import DesignSystem
import SwiftUI

extension ReviewView {
    @ViewBuilder
    var storeReviewCard: some View {
        if model.state.showsStoreReviewCard {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader("使ってみていかがですか", systemImage: "star")

                Text("レビューが開発の励みになります。感想をひとこといただけるとうれしいです。")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    CardButton("レビューを書く", style: .filled, action: writeStoreReview)

                    CardButton(
                        "閉じる",
                        style: .outlined(Palette.subtext),
                        action: closeStoreReviewCard
                    )
                    .frame(width: Self.storeReviewCloseWidth)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }
}

private extension ReviewView {
    static let storeReviewCloseWidth: CGFloat = 96

    func writeStoreReview() {
        if let url = SettingsMenuLink.review {
            openURL(url)
        }

        Task {
            await model.openStoreReview()
        }
    }

    func closeStoreReviewCard() {
        Task {
            await model.closeStoreReviewCard()
        }
    }
}
