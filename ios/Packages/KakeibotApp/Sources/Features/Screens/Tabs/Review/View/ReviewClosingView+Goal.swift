import Core
import DesignSystem
import SwiftUI

extension ReviewClosingView {
    struct Goals {
        let answer: ReviewGoalItem?
        let next: Next
        let nextName: String
        let nextStart: LocalDate
        let checkDate: LocalDate
    }

    struct Reason: Hashable {
        let text: String
        let isWritten: Bool
    }

    enum Next {
        case none
        case rest
        case goal(ReviewGoalItem, reason: Reason?)
    }

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

    func answerCard(_ item: ReviewGoalItem) -> some View {
        let goal = item.goal
        let isAchieved = goal.isAchieved ?? false
        let result = goal.result ?? 0

        let scale = Double(max(goal.baseline, result, goal.target)) * 1.15
        let targetRatio = Double(goal.target) / max(scale, 1)
        let baselineRatio = Double(goal.baseline) / max(scale, 1)
        let resultRatio = Double(result) / max(scale, 1)
        let resultFill = isAchieved ? AnyShapeStyle(Palette.gold) : AnyShapeStyle(Palette.increase)

        return VStack(alignment: .leading, spacing: 16) {
            ReviewReportLabel(title: "\(name)の一手")

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("答え合わせ")
                        .displayFont(.headline, weight: .bold)
                        .foregroundStyle(Palette.text)

                    Text("「\(item.title(unit: unit))」")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                seal(isAchieved)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(goal.kind == .count ? "\(unit)の回数" : "1 回の平均")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                goalBar(
                    previousName,
                    value: item.value(goal.baseline),
                    ratio: baselineRatio,
                    target: targetRatio,
                    fill: AnyShapeStyle(Palette.subtext.opacity(.medium)),
                    isCurrent: false
                )

                goalBar(
                    name,
                    value: item.value(result),
                    ratio: resultRatio,
                    target: targetRatio,
                    fill: resultFill,
                    isCurrent: true
                )

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Palette.text)
                        .frame(width: 2, height: 10)

                    Text("目標 \(item.value(goal.target))")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("浮いた金額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(ReviewYen.text(goal.saved ?? 0))
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Palette.accent.opacity(.faint),
                in: .rect(cornerRadius: ReviewReportRadius.panel)
            )
            .overlay {
                RoundedRectangle(cornerRadius: ReviewReportRadius.panel)
                    .strokeBorder(Palette.accent.opacity(.soft))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
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
        reason: Reason?
    ) -> some View {
        let goal = item.goal
        let start = goals.nextStart
        let check = goals.checkDate

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
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

            Rectangle()
                .stroke(
                    Palette.accent.opacity(.muted),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

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

            VStack(spacing: 12) {
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
        .reviewTicket()
    }

    func goalBar(
        _ title: String,
        value: String,
        ratio: Double,
        target: Double,
        fill: AnyShapeStyle,
        isCurrent: Bool
    ) -> some View {
        let valueColor = isCurrent ? Palette.accent : Palette.subtext

        return HStack(spacing: 8) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 40, alignment: .leading)

            Capsule()
                .fill(Palette.accent.opacity(.subtle))
                .frame(height: 12)
                .overlay {
                    GeometryReader { proxy in
                        let width = proxy.size.width

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(fill)
                                .frame(width: width * min(ratio, 1), height: proxy.size.height)

                            Rectangle()
                                .fill(Palette.text)
                                .frame(width: 2, height: 20)
                                .offset(x: width * target - 1)
                        }
                        .frame(height: proxy.size.height)
                    }
                }

            Text(value)
                .displayFont(style: .subheadline, weight: .bold)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .fixedSize()
                .frame(minWidth: 52, alignment: .trailing)
        }
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

            VStack(spacing: 2) {
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

    func seal(_ isAchieved: Bool) -> some View {
        let color = isAchieved ? Palette.accent : Palette.subtext

        return Text(isAchieved ? "達成" : "あと\n少し")
            .displayFont(.headline, weight: .bold)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .frame(width: 72, height: 72)
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: 2.5)
            }
            .overlay {
                Circle()
                    .strokeBorder(color.opacity(.medium), lineWidth: 1)
                    .padding(4)
            }
            .rotationEffect(.degrees(-12))
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

    static func reasonText(_ reason: Reason) -> Text {
        guard reason.isWritten else {
            return Text(reason.text)
        }

        let sparkle = Text(Image(systemName: "sparkles"))
            .foregroundStyle(Palette.gold)

        return Text("\(sparkle) \(reason.text)")
    }
}
