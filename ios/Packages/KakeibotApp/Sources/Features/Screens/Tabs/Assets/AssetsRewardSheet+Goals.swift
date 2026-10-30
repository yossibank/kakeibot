import Core
import DesignSystem
import SwiftUI

extension AssetsRewardSheet {
    var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("目標")

                Spacer()

                if !model.waitingGoals.isEmpty {
                    ToolButton(systemImage: "plus") {
                        goalTarget = GoalTarget(goal: nil)
                    }
                }
            }

            if model.waitingGoals.isEmpty {
                AddButton("欲しい物を目標にする") {
                    goalTarget = GoalTarget(goal: nil)
                }
            } else {
                ForEach(model.waitingGoals) { goal in
                    goalRow(goal)
                }
            }
        }
        .sharesTextScale(id: model.waitingGoals.map(\.name))
    }

    var boughtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("買ったもの")

            ForEach(model.boughtGoals) { goal in
                boughtRow(goal)
            }
        }
        .sharesTextScale(id: model.boughtGoals.map(\.name))
    }
}

private extension AssetsRewardSheet {
    func goalRow(_ goal: RewardGoal) -> some View {
        AssetsGoalCard(
            name: goal.name,
            targetAmount: goal.targetAmount,
            remaining: model.remaining(to: goal),
            progress: model.progress(to: goal),
            onBuy: {
                Task {
                    await buy(goal)
                }
            }
        )
        .contentShape(.rect)
        .onTapGesture {
            goalTarget = GoalTarget(goal: goal)
        }
    }

    func boughtRow(_ goal: RewardGoal) -> some View {
        let date = goal.purchasedAt ?? goal.updatedAt

        return HStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .sansFont(.body)
                .foregroundStyle(Palette.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

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
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .card()
    }
}

private extension AssetsRewardSheet {
    func buy(_ goal: RewardGoal) async {
        if await model.setPurchased(goal.id, isPurchased: true) {
            boughtId = goal.id
        }
    }
}
