import Core
import DesignSystem
import SwiftUI

struct WhatsNewReviewScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .reviewClosing:
            closing

        case .reviewGoal:
            goal

        default:
            pace
        }
    }
}

private extension WhatsNewReviewScene {
    static var samplePace: ReviewPace? {
        guard
            let start = LocalDate(year: 2026, month: 11, day: 1),
            let end = LocalDate(year: 2026, month: 11, day: 30),
            let today = LocalDate(year: 2026, month: 11, day: 15)
        else {
            return nil
        }

        return ReviewPace(
            limit: 60000,
            basis: .budget,
            spent: 28000,
            range: start...end,
            today: today
        )
    }

    @ViewBuilder
    var pace: some View {
        if let pace = Self.samplePace {
            VStack(spacing: 4) {
                ReviewReportGauge(
                    pace: pace,
                    limitName: "予算",
                    showsMarker: true,
                    size: 100
                )

                HStack(spacing: 4) {
                    Text("1日")
                        .foregroundStyle(Palette.subtext)

                    AmountText(pace.perDay, font: .size(.caption, weight: .bold))
                        .foregroundStyle(Palette.text)

                    Text("まで")
                        .foregroundStyle(Palette.subtext)
                }
                .textFont(size: .micro, weight: .semibold)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(Palette.accent.opacity(.faint), in: .capsule)
            }
        }
    }

    var closing: some View {
        VStack(alignment: .leading, spacing: 8) {
            ReviewReportLabel(title: "10月の結果")

            HStack(spacing: 4) {
                Text("予算内")
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.text)

                Spacer(minLength: 0)

                seal
            }

            HStack(spacing: 2) {
                Text("あと")

                AmountText(4200, font: .size(.micro, weight: .semibold))

                Text("残りました")
            }
            .textFont(size: .micro)
            .foregroundStyle(Palette.subtext)
            .fixedSize()
        }
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var seal: some View {
        Text("達成")
            .textFont(size: .caption, weight: .bold)
            .foregroundStyle(Palette.accent)
            .frame(width: 36, height: 36)
            .overlay {
                Circle()
                    .strokeBorder(Palette.accent, lineWidth: 2)
            }
            .overlay {
                Circle()
                    .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
                    .padding(4)
            }
            .rotationEffect(.degrees(-12))
    }

    var goal: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                ReviewReportLabel(title: "11月の一手")

                Text("外食は 4 回まで")
                    .textFont(size: .small, weight: .bold)
                    .foregroundStyle(Palette.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(8)

            Rectangle()
                .stroke(
                    Palette.accent.opacity(.muted),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .frame(height: 1)
                .padding(.horizontal, 8)

            HStack {
                Text("浮く金額")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 4)

                AmountText(3200, font: .size(.caption, weight: .bold))
                    .foregroundStyle(Palette.gold)
            }
            .padding(8)
        }
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }
}
