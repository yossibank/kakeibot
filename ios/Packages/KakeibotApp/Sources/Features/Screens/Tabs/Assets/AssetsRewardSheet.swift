import Core
import DesignSystem
import Store
import SwiftUI

struct AssetsRewardSheet: View {
    @State private var goalTarget: GoalTarget?
    @State private var boughtId: RewardGoal.ID?
    @State private var isEditingRules = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(AmountText.text(model.rewardBalance))
                    .displayFont(.largeTitle)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

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
            }
        }
    }

    var boughtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("買ったもの")

            ForEach(model.boughtGoals) { goal in
                boughtRow(goal)
            }
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("達成の履歴")

            if model.rewardHistory.isEmpty {
                Text("資産の「今日の達成を付ける」か、記録の日の見出しの贈り物のボタンから付けられます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 8)
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

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.name)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text("＋\(AmountText.text(rule.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
    }

    func boughtRow(_ goal: RewardGoal) -> some View {
        let date = goal.purchasedAt ?? goal.updatedAt

        return HStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.footnote)
                .foregroundStyle(Palette.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
            .padding(16)
            .card()
        }
    }

    func logRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 12) {
            IconBadge(icon, size: 26)

            Text(rule?.name ?? "")
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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
