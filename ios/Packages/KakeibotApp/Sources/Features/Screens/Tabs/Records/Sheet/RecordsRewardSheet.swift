import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct RecordsRewardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: RecordsModel
    let date: LocalDate

    public init(
        model: RecordsModel,
        date: LocalDate
    ) {
        self.model = model
        self.date = date
    }

    public var body: some View {
        FittedSheet {
            VStack(spacing: 20) {
                header

                if rules.isEmpty {
                    RecordsSheetPlaceholder(
                        systemImage: "gift",
                        title: "ごほうびの決まりがまだありません",
                        message: "決まりを作ると、ここで達成を付けられます",
                        actionTitle: "決まりを追加"
                    ) {
                        model.state.presented.adding.show(.mark)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(rules) { rule in
                            row(rule)
                        }
                    }
                    .sharesTextScale(id: rules.map(\.name))

                    total
                }
            }
        }
        .sheet(isPresented: Bindable(model.state).presented.adding[.mark]) {
            RewardRuleEditSheet(model: model.rewardRuleEditModel())
        }
        .onAppear {
            model.state.finishAddingMark()
        }
        .haptic(.success, trigger: model.output.rewardTotal(on: date))
    }
}

private extension RecordsRewardSheet {
    var header: some View {
        SheetHeader("\(date.monthDayText) のごほうび") {
            dismiss()
        } trailing: {
            if rules.isEmpty {
                SheetHeaderSlot()
            } else {
                RingButton(systemImage: "plus") {
                    model.state.presented.adding.show(.mark)
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

            AmountText(
                model.output.rewardTotal(on: date),
                font: .size(.headline),
                color: Palette.accentStrong
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText())
            .animation(.snappy, value: model.output.rewardTotal(on: date))
        }
        .padding(.horizontal, 8)
    }

    func row(_ rule: RewardRule) -> some View {
        let isAchieved = model.output.isAchieved(rule, on: date)
        let mark = isAchieved ? "checkmark.circle.fill" : "circle"
        let stroke = isAchieved ? Palette.accent : Palette.line

        return Button {
            model.perform {
                await $0.toggleReward(rule, on: date)
            }
        } label: {
            HStack(spacing: 12) {
                IconBadge(model.output.rewardIcon(for: rule), size: 36)

                Text(rule.name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                Spacer(minLength: 8)

                AmountText(
                    rule.amount,
                    font: .style(.footnote),
                    sign: .plus,
                    color: Palette.accent
                )

                Image(systemName: mark)
                    .sansFont(.headline)
                    .foregroundStyle(Palette.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 16)
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

private extension RecordsRewardSheet {
    var rules: [RewardRule] {
        model.output.rewardRules(on: date)
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}
