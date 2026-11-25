import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension AssetsRewardSheet {
    var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("目標")

                Spacer()

                if !model.output.waitingGoals.isEmpty {
                    ToolButton(systemImage: "plus") {
                        model.state.editGoal(nil)
                    }
                }
            }

            if model.output.waitingGoals.isEmpty {
                AddButton("欲しい物を目標にする") {
                    model.state.editGoal(nil)
                }
            } else {
                ForEach(model.output.waitingGoals) { goal in
                    goalRow(goal)
                }
            }
        }
        .sharesTextScale(id: model.output.waitingGoals.map(\.name))
    }

    var boughtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("買ったもの")

            ForEach(model.output.boughtGoals) { goal in
                boughtRow(goal)
            }
        }
        .sharesTextScale(id: model.output.boughtGoals.map(\.name))
    }
}

private extension AssetsRewardSheet {
    func goalRow(_ goal: RewardGoal) -> some View {
        AssetsRewardGoalCard(
            name: goal.name,
            targetAmount: goal.targetAmount,
            remaining: model.output.remaining(to: goal),
            progress: model.output.progress(to: goal),
            onBuy: {
                model.perform {
                    await $0.setPurchased(goal.id, isPurchased: true)
                }
            }
        )
        .contentShape(.rect)
        .onTapGesture {
            model.state.editGoal(goal)
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

            AmountText(-goal.targetAmount, font: .style(.footnote), color: Palette.subtext)

            Button {
                model.perform {
                    await $0.setPurchased(goal.id, isPurchased: false)
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
