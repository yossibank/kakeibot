import Core
import DesignSystem
import SwiftUI

struct WhatsNewScene: View {
    @Environment(\.themeStyle.corner) private var corner

    let kind: Kind

    var body: some View {
        FeatureArtCanvas(width: Self.size, height: Self.size) {
            content
        }
        .padding(2)
        .background(Palette.faint, in: .rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
                .stroke(Palette.hairline, lineWidth: 1)
        }
    }
}

extension WhatsNewScene {
    enum Kind: Hashable, Sendable {
        case receipt(WhatsNewReceiptScene.Step)
        case items(WhatsNewItemsScene.Step)
        case carryover(WhatsNewCarryoverScene.Step)
        case monthStart(WhatsNewMonthStartScene.Step)
        case bill(WhatsNewBillScene.Step)
        case recurring(WhatsNewRecurringScene.Step)
        case loan(WhatsNewLoanScene.Step)
        case icon(WhatsNewIconScene.Step)
        case plan(WhatsNewPlanScene.Step)
        case pager(WhatsNewPagerScene.Step)
        case wallet(WhatsNewWalletScene.Step)
        case outlook(WhatsNewOutlookScene.Step)
        case voice(WhatsNewVoiceScene.Step)
        case entry(WhatsNewEntryScene.Step)
        case pad(WhatsNewPadScene.Step)
        case upcoming(WhatsNewUpcomingScene.Step)
        case widget(WhatsNewWidgetScene.Step)
        case analysis(WhatsNewAnalysisScene.Step)
        case review(WhatsNewReviewScene.Step)
    }
}

private extension WhatsNewScene {
    @ViewBuilder
    var content: some View {
        switch kind {
        case let .receipt(step):
            WhatsNewReceiptScene(step: step)

        case let .items(step):
            WhatsNewItemsScene(step: step)

        case let .carryover(step):
            WhatsNewCarryoverScene(step: step)

        case let .monthStart(step):
            WhatsNewMonthStartScene(step: step)

        case let .bill(step):
            WhatsNewBillScene(step: step)

        case let .recurring(step):
            WhatsNewRecurringScene(step: step)

        case let .loan(step):
            WhatsNewLoanScene(step: step)

        case let .icon(step):
            WhatsNewIconScene(step: step)

        case let .plan(step):
            WhatsNewPlanScene(step: step)

        case let .pager(step):
            WhatsNewPagerScene(step: step)

        case let .wallet(step):
            WhatsNewWalletScene(step: step)

        case let .outlook(step):
            WhatsNewOutlookScene(step: step)

        case let .voice(step):
            WhatsNewVoiceScene(step: step)

        case let .entry(step):
            WhatsNewEntryScene(step: step)

        case let .pad(step):
            WhatsNewPadScene(step: step)

        case let .upcoming(step):
            WhatsNewUpcomingScene(step: step)

        case let .widget(step):
            WhatsNewWidgetScene(step: step)

        case let .analysis(step):
            WhatsNewAnalysisScene(step: step)

        case let .review(step):
            WhatsNewReviewScene(step: step)
        }
    }
}

private extension WhatsNewScene {
    static let size: CGFloat = 140
}

extension View {
    func whatsNewTapped() -> some View {
        allowsHitTesting(false)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.accentStrong)
                    .shadow(color: Palette.shadow, radius: 3, y: 1)
                    .offset(x: 14, y: 26)
            }
    }
}
