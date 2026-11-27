import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewClosingView {
    func answerCard(_ item: ReviewGoalItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ReviewReportTitle(title: "\(name)の一手")

            answerHeader(item)

            answerBars(item)

            answerSaved(item.goal)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    func answerHeader(_ item: ReviewGoalItem) -> some View {
        let isAchieved = item.goal.isAchieved ?? false

        return HStack(alignment: .top, spacing: 12) {
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
    }

    func answerBars(_ item: ReviewGoalItem) -> some View {
        let goal = item.goal
        let isAchieved = goal.isAchieved ?? false
        let result = goal.result ?? 0

        let scale = Double(max(goal.baseline, result, goal.target)) * 1.15
        let targetRatio = Double(goal.target) / max(scale, 1)
        let baselineRatio = Double(goal.baseline) / max(scale, 1)
        let resultRatio = Double(result) / max(scale, 1)
        let resultFill = isAchieved ? AnyShapeStyle(Palette.gold) : AnyShapeStyle(Palette.increase)

        return VStack(alignment: .leading, spacing: 8) {
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
    }

    func answerSaved(_ goal: ReviewGoal) -> some View {
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
