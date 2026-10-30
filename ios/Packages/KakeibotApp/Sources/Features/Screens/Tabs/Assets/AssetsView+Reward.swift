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
        .padding(16)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 26, height: 26)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                SectionTitle("ごほうび貯金箱")

                Spacer()

                if model.isRewardGoalReached {
                    Text("目標に届きました")
                        .textFont(.caption2, weight: .semibold)
                        .foregroundStyle(Palette.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Palette.accent, in: .capsule)
                }

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }

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
                .sharesTextScale(id: model.recentRewards)
            }
        }
        .contentShape(.rect)
    }

    func goalLine(_ goal: RewardGoal) -> some View {
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)
        let note = remaining > 0 ? "あと \(AmountText.text(remaining))" : "届きました"

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(goal.name) まで")
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text(note)
                    .textFont(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }

            RatioBar(progress, tint: Palette.accent, height: 6)
        }
    }

    func rewardRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 12) {
            IconBadge(icon, size: 26)

            Text(rule?.name ?? "")
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 8)

            Text("\(log.date.month)/\(log.date.day)")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Text("+\(AmountText.text(log.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
    }
}
