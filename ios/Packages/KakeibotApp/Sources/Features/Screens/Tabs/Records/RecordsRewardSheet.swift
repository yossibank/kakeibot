import Core
import DesignSystem
import SwiftUI

struct RecordsRewardSheet: View {
    @State private var isAddingRule = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: RecordsModel
    let date: LocalDate

    var body: some View {
        FittedSheet {
            VStack(spacing: 18) {
                header

                if model.rewardRules.isEmpty {
                    RecordsSheetEmpty(
                        systemImage: "gift",
                        title: "ごほうびの決まりがまだありません",
                        message: "決まりを作ると、ここで達成を付けられます",
                        actionTitle: "ごほうびを作る"
                    ) {
                        isAddingRule = true
                    }
                } else {
                    if let buddy = model.buddy.buddy {
                        BuddyBubble(
                            buddy,
                            name: model.buddy.name,
                            line: model.rewardLine(on: date)
                        )
                    }

                    VStack(spacing: 8) {
                        ForEach(model.rewardRules) { rule in
                            row(rule)
                        }
                    }

                    total
                }
            }
        }
        .sheet(isPresented: $isAddingRule) {
            RewardRuleEditSheet(model: model.rewardRuleEditModel())
        }
        .sensoryFeedback(.success, trigger: model.rewardTotal(on: date))
    }
}

private extension RecordsRewardSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("\(date.month)/\(date.day) のごほうび")
                .displayFont(.body)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            if model.rewardRules.isEmpty {
                Color.clear
                    .frame(width: 44, height: 44)
            } else {
                RingButton(systemImage: "plus") {
                    isAddingRule = true
                }
            }
        }
    }

    var total: some View {
        HStack {
            Text("この日に貯めた額")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            Spacer()

            Text(AmountText.text(model.rewardTotal(on: date)))
                .displayFont(.headline)
                .foregroundStyle(Palette.accentStrong)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.rewardTotal(on: date))
        }
        .padding(.horizontal, 6)
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    func row(_ rule: RewardRule) -> some View {
        let isAchieved = model.isAchieved(rule, on: date)
        let mark = isAchieved ? "checkmark.circle.fill" : "circle"
        let stroke = isAchieved ? Palette.accent : Palette.line

        return Button {
            Task {
                await model.toggleReward(rule, on: date)
            }
        } label: {
            HStack(spacing: 12) {
                IconBadge(model.rewardIcon(for: rule), size: 36)

                Text(rule.name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("＋\(AmountText.text(rule.amount))")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accent)

                Image(systemName: mark)
                    .sansFont(.headline)
                    .foregroundStyle(Palette.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(Palette.panel, in: shape)
            .overlay {
                shape
                    .stroke(stroke, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
