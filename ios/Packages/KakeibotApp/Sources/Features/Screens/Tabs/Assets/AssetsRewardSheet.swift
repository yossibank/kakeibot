import Core
import DesignSystem
import Store
import SwiftUI

struct AssetsRewardSheet: View {
    @State private var goalTarget: GoalTarget?
    @State private var boughtId: RewardGoal.ID?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: AssetsModel

    var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    balanceCard
                    goalSection

                    if !model.boughtGoals.isEmpty {
                        boughtSection
                    }

                    historySection
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .sheet(item: $goalTarget) { target in
            AssetsGoalSheet(model: model.goalEditModel(editing: target.goal))
        }
        .settingsHideNotice(
            $boughtId,
            message: "買ったものに移しました",
            systemImage: "bag"
        ) { id in
            Task {
                await model.setPurchased(id, isPurchased: false)
            }
        }
    }
}

private extension AssetsRewardSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("ごほうび貯金箱")
                .displayFont(.body)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var balanceCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "gift")
                .sansFont(.title, weight: .light)
                .foregroundStyle(Palette.accent)

            Text("頑張りで浮いた分")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(model.rewardBalance))
                .displayFont(.largeTitle)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)

            Text("本物の口座のお金とは別に数えます")
                .textFont(.caption2)
                .foregroundStyle(Palette.hint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .card()
    }

    var goalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle("目標")
                Spacer()

                Button {
                    goalTarget = GoalTarget(goal: nil)
                } label: {
                    Label("決める", systemImage: "plus")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }

            if model.waitingGoals.isEmpty {
                Text("欲しい物と額を決めると、あといくらで届くか分かります")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 6)
            } else {
                ForEach(model.waitingGoals) { goal in
                    goalRow(goal)
                }
            }
        }
    }

    var boughtSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("買ったもの")

            ForEach(model.boughtGoals) { goal in
                boughtRow(goal)
            }
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("達成の履歴")

            if model.rewardHistory.isEmpty {
                Text("記録の日の見出しの贈り物のボタンから、達成を付けられます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 6)
            } else {
                ForEach(model.rewardHistory) { month in
                    monthBlock(month)
                }
            }
        }
    }

    func goalRow(_ goal: RewardGoal) -> some View {
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.name)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(AmountText.text(goal.targetAmount))
                    .textFont(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            RatioBar(progress, tint: Palette.accent, height: 8)

            HStack {
                if remaining > 0 {
                    Text("あと \(AmountText.text(remaining))")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accent)
                } else {
                    Text("届きました")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                }

                Spacer()

                if remaining == 0 {
                    Button {
                        Task {
                            await buy(goal)
                        }
                    } label: {
                        Text("買った")
                            .textFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Palette.accent, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .card()
        .contentShape(.rect)
        .onTapGesture {
            goalTarget = GoalTarget(goal: goal)
        }
    }

    func boughtRow(_ goal: RewardGoal) -> some View {
        let date = goal.purchasedAt ?? goal.updatedAt

        return HStack(spacing: 10) {
            Image(systemName: "bag.fill")
                .font(.footnote)
                .foregroundStyle(Palette.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(date.formatted(.dateTime.year().month().day()))
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            Text("−\(AmountText.text(goal.targetAmount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Button {
                Task {
                    await model.setPurchased(goal.id, isPurchased: false)
                }
            } label: {
                Label("戻す", systemImage: "arrow.uturn.backward")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                Palette.accent.opacity(.medium),
                                lineWidth: 0.8
                            )
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 56)
        .card()
    }

    func monthBlock(_ month: AssetsModel.RewardMonth) -> some View {
        let total = month.logs.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(String(month.month.year))年 \(month.month.month)月")
                    .textFont(.footnote, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Spacer()

                Text("＋\(AmountText.text(total))")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }

            VStack(spacing: 8) {
                ForEach(month.logs) { log in
                    logRow(log)
                }
            }
            .padding(14)
            .card()
        }
    }

    func logRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 10) {
            IconBadge(icon, size: 26)

            Text(rule?.name ?? "")
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(log.date.month)/\(log.date.day)")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Text("＋\(AmountText.text(log.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
    }
}

private extension AssetsRewardSheet {
    func buy(_ goal: RewardGoal) async {
        if await model.setPurchased(goal.id, isPurchased: true) {
            boughtId = goal.id
        }
    }
}

private extension AssetsRewardSheet {
    struct GoalTarget: Identifiable {
        let goal: RewardGoal?

        var id: String {
            goal?.id.description ?? "new"
        }
    }
}
