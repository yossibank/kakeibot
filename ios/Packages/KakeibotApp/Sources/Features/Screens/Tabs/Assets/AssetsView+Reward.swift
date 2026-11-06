import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var rewardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isShowingReward = true
            } label: {
                rewardCardBody
            }
            .buttonStyle(.plain)

            if model.rewardGoal == nil {
                AddButton("欲しい物を目標にする") {
                    isAddingGoal = true
                }
            }

            Button(action: onMarkReward) {
                Label("今日の達成を付ける", systemImage: "gift")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
        .overlay {
            if model.isRewardGoalReached {
                RoundedRectangle(cornerRadius: corner.radius(24))
                    .strokeBorder(Palette.accent, lineWidth: 1.5)
                    .glow(Palette.accent, radius: 10)
                    .phaseAnimator([false, true]) { content, isLit in
                        let opacity = isLit ? 1 : 0.3

                        content
                            .opacity(opacity)
                    } animation: { _ in
                        .easeInOut(duration: 1.4)
                    }
                    .allowsHitTesting(false)
            }
        }
    }
}

private extension AssetsView {
    var rewardCardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("ごほうび貯金箱", systemImage: "gift.fill") {
                if model.isRewardGoalReached {
                    Text("目標に届きました")
                        .textFont(.caption2, weight: .semibold)
                        .foregroundStyle(Palette.background)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Palette.accent, in: .capsule)
                }

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }

            rewardContent
        }
        .contentShape(.rect)
    }

    var rewardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AmountText.text(model.rewardBalance))
                    .displayFont(.title)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("我慢できた日に決めた額を貯めていきます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text("口座の残高は変わりません")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.hint)
            }

            if let goal = model.rewardGoal {
                goalLine(goal)
            }

            if !model.recentRewards.isEmpty {
                VStack(spacing: 8) {
                    ForEach(model.recentRewards) { log in
                        rewardRow(log)
                    }
                }
            }
        }
    }

    func goalLine(_ goal: RewardGoal) -> some View {
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)
        let note = remaining > 0 ? "あと \(AmountText.text(remaining))" : "届きました"

        return VStack(alignment: .leading, spacing: 8) {
            Text("\(goal.name) まで")
                .textFont(.caption, weight: .semibold)
                .foregroundStyle(Palette.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            RatioBar(progress, tint: Palette.accent, height: 6)

            HStack(alignment: .firstTextBaseline) {
                Text("目標 \(AmountText.text(goal.targetAmount))")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(note)
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
            }
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    func rewardRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 12) {
            IconBadge(icon, size: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule?.name ?? "")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(log.date.month)/\(log.date.day)")
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            Text("+\(AmountText.text(log.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
    }
}
