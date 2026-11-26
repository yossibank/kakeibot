import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewClosingView {
    @ViewBuilder
    var nextCard: some View {
        switch goals.next {
        case .none:
            EmptyView()

        case .rest:
            restCard

        case let .goal(item, reason):
            ticket(item, reason: reason)
        }
    }
}

private extension ReviewClosingView {
    var restCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ReviewReportLabel(title: "\(goals.nextName)の一手")

            Text("一手はお休みです")
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)
                .padding(.top, 4)

            Text("いつもより多いカテゴリはありませんでした。このまま続けましょう。")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }

    func ticket(
        _ item: ReviewGoalItem,
        reason: ReviewClosing.Reason?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ticketHead(item, reason: reason)

            Rectangle()
                .stroke(
                    Palette.accent.opacity(.muted),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            ticketSaving(item.goal)

            ticketFoot(item)
        }
        .reviewTicket()
    }

    func ticketHead(
        _ item: ReviewGoalItem,
        reason: ReviewClosing.Reason?
    ) -> some View {
        let start = goals.nextStart

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ReviewReportLabel(title: "\(goals.nextName)の一手")

                Text("\(start.monthDayText) から")
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(Palette.backgroundBottom)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.gold, in: Capsule())
                    .fixedSize()
            }

            Text(item.title(unit: unit))
                .displayFont(.title, weight: .bold)
                .foregroundStyle(Palette.gold)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            if let reason {
                Self.reasonText(reason)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            goalStep(item)
                .padding(.top, 4)
        }
        .padding(20)
    }

    func ticketSaving(_ goal: ReviewGoal) -> some View {
        HStack {
            Text("守れたら浮く金額")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            Text(ReviewYen.text(goal.saving))
                .displayFont(.largeTitle, weight: .bold)
                .foregroundStyle(Palette.gold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(20)
    }

    func ticketFoot(_ item: ReviewGoalItem) -> some View {
        let check = goals.checkDate

        return VStack(spacing: 12) {
            Text("途中経過で進み具合を見て、\(check.monthDayText) に答え合わせします")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            BandLinkButton("\(item.name)をくわしく見る") {
                onOpenGoal(item)
            }
        }
        .padding([.horizontal, .bottom], 20)
    }

    func goalStep(_ item: ReviewGoalItem) -> some View {
        let goal = item.goal
        let caption = goal.kind == .count ? "\(name)の回数" : "\(name)の 1 回"
        let change = Self.changePercent(from: goal.baseline, to: goal.target)

        return HStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(caption)
                    .textFont(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(item.value(goal.baseline))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .fixedSize()
            }
            .foregroundStyle(Palette.subtext)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                Palette.subtext.opacity(.faint),
                in: .rect(cornerRadius: ReviewReportRadius.panel)
            )

            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .sansFont(.small, weight: .bold)
                    .foregroundStyle(Palette.cardBottom)
                    .frame(width: 28, height: 28)
                    .background(Palette.gold, in: Circle())

                Text("\(change)%")
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .fixedSize()
            }

            goalTarget(item)
        }
    }

    func goalTarget(_ item: ReviewGoalItem) -> some View {
        let goal = item.goal

        return VStack(spacing: 2) {
            Text("目標")
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.accent)

            Text(item.value(goal.target))
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.gold)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: ReviewReportRadius.panel)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ReviewReportRadius.panel)
                .strokeBorder(Palette.accent.opacity(.strong), lineWidth: 1.5)
        }
    }
}

private extension ReviewClosingView {
    static func changePercent(
        from baseline: Int,
        to target: Int
    ) -> String {
        guard baseline > 0 else {
            return "0"
        }

        let ratio = Double(target - baseline) / Double(baseline) * 100
        let percent = Int(ratio.rounded())

        return percent < 0 ? "−\(-percent)" : "+\(percent)"
    }

    static func reasonText(_ reason: ReviewClosing.Reason) -> Text {
        guard reason.isWritten else {
            return Text(reason.text)
        }

        let sparkle = Text(Image(systemName: "sparkles"))
            .foregroundStyle(Palette.gold)

        return Text("\(sparkle) \(reason.text)")
    }
}
