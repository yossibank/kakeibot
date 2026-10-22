import Core
import DesignSystem
import SwiftUI

struct RecordsRewardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: RecordsModel
    let date: LocalDate

    var body: some View {
        VStack(spacing: 18) {
            header

            if model.rewardRules.isEmpty {
                Text("設定の「ごほうび」で決まりを作ると、ここで達成を付けられます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.rewardRules) { rule in
                            row(rule)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)

                total
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: model.rewardTotal(on: date))
        .presentationDetents([.medium, .large])
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

            Color.clear
                .frame(width: 44, height: 44)
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

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}
