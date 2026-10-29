import Core
import DesignSystem
import SwiftUI

struct AssetsRewardSheet: View {
    @State var goalTarget: GoalTarget?
    @State var boughtId: RewardGoal.ID?

    @State private var isEditingRules = false

    @Environment(\.dismiss) private var dismiss

    let model: AssetsModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        balanceCard

                        guideSection

                        goalSection

                        ruleSection

                        if !model.boughtGoals.isEmpty {
                            boughtSection
                        }

                        historySection
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background {
                Rectangle()
                    .fill(Palette.background)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isEditingRules) {
                RewardRuleListView(database: model.database)
            }
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

extension AssetsRewardSheet {
    struct GoalTarget {
        let goal: RewardGoal?
    }
}

private extension AssetsRewardSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            SheetTitle("ごほうび貯金箱")

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var balanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(AmountText.text(model.rewardBalance))
                    .displayFont(.largeTitle)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 8)

                Image(systemName: "gift")
                    .sansFont(.title, weight: .light)
                    .foregroundStyle(Palette.accent)
            }

            if let goal = model.rewardGoal {
                nearestGoal(goal)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我慢できた日に決めた額を貯めていきます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Text("口座の残高は変わりません")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.hint)
                }
            }
        }
        .padding(20)
        .card()
    }

    var guideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("使い方")

            VStack(alignment: .leading, spacing: 12) {
                guideStep(
                    1,
                    title: "ごほうびの決まりを作る",
                    note: "例：外食しなかったら ¥500"
                )

                guideStep(
                    2,
                    title: "守れた日に「今日の達成を付ける」を押す",
                    note: nil
                )

                guideStep(
                    3,
                    title: "目標の額まで貯まったら買う",
                    note: nil
                )
            }
            .padding(16)
            .card()
        }
    }

    var ruleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("ごほうびの決まり")

                Spacer()

                Button {
                    isEditingRules = true
                } label: {
                    HStack(spacing: 4) {
                        Text("編集")

                        Image(systemName: "chevron.right")
                            .sansFont(.micro, weight: .bold)
                    }
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
            }

            if model.rewardRules.isEmpty {
                AddButton("ごほうびを追加") {
                    isEditingRules = true
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(model.rewardRules, id: \.id) { rule in
                        ruleRow(rule)
                    }
                }
                .padding(16)
                .card()
                .sharesTextScale(id: model.rewardRules.map(\.name))
            }
        }
    }

    func nearestGoal(_ goal: RewardGoal) -> some View {
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)
        let percent = model.percent(to: goal)
        let note = remaining > 0 ? "あと \(AmountText.text(remaining))" : "届きました"

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(goal.name) まで")
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                Spacer(minLength: 8)

                Text(note)
                    .textFont(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }

            HStack(spacing: 8) {
                RatioBar(progress, tint: Palette.accent, height: 8)

                Text("\(percent)%")
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }
        }
        .sharesTextScale(id: goal.name)
    }

    func guideStep(
        _ number: Int,
        title: String,
        note: String?
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .textFont(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .frame(width: 22, height: 22)
                .background(Palette.accent.opacity(.subtle), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)

                if let note {
                    Text(note)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func ruleRow(_ rule: RewardRule) -> some View {
        HStack(spacing: 12) {
            IconBadge(model.rewardIcon(for: rule), size: 26)

            Text(rule.name)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .sharedTextScale()

            Spacer(minLength: 8)

            Text("+\(AmountText.text(rule.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
    }
}

extension AssetsRewardSheet.GoalTarget: Identifiable {
    var id: String {
        goal?.id.description ?? "new"
    }
}
