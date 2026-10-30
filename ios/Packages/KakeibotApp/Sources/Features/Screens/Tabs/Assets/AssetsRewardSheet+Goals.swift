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
                    Button {
                        goalTarget = GoalTarget(goal: nil)
                    } label: {
                        Label("追加", systemImage: "plus")
                            .textFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
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
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.name)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .sharedTextScale()

                Spacer(minLength: 8)

                Text(AmountText.text(goal.targetAmount))
                    .textFont(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Palette.accent, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .card()
        .contentShape(.rect)
        .onTapGesture {
            goalTarget = GoalTarget(goal: goal)
        }
    }

    func boughtRow(_ goal: RewardGoal) -> some View {
        let date = goal.purchasedAt ?? goal.updatedAt

        return HStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .sansFont(.small)
                .foregroundStyle(Palette.accent)
                .frame(width: 26)

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
