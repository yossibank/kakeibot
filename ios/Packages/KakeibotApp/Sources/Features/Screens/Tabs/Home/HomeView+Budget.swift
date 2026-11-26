import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension HomeView {
    var dialCard: some View {
        VStack(spacing: 16) {
            dialGauge

            dialLinks

            dialStats
        }
        .padding(16)
        .padding(.top, 4)
        .card()
    }
}

private extension HomeView {
    var dialGauge: some View {
        ZStack(alignment: .bottom) {
            HalfDial(progress: dialProgress, tint: dialTint)

            VStack(spacing: 2) {
                Text(dialTitle)
                    .textFont(size: .caption)
                    .tracking(4)
                    .foregroundStyle(Palette.accent)

                Text(dialAmount)
                    .displayFont(.display, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(dialAmountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: 290)
        .animation(.snappy, value: model.output.budgetUsage)
    }

    var dialLinks: some View {
        VStack(spacing: 4) {
            budgetLink

            if hasRecurringRow {
                recurringLink
            }
        }
    }

    @ViewBuilder
    var budgetLink: some View {
        if let usage = model.output.budgetUsage {
            VStack(spacing: 4) {
                if !model.input.list.isFailed,
                   let warning = usage.warningText {
                    Text(warning)
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(usage.tint)
                }

                Button {
                    onOpenSetup(.budget)
                } label: {
                    HStack(spacing: 4) {
                        Text(usage.budgetText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        DisclosureMark(.link)
                    }
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 4)
                    .tapArea(budgetLinkTapOutsets)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button {
                onOpenSetup(.budget)
            } label: {
                HStack(spacing: 4) {
                    Text("予算を決めると、あといくら使えるかが出ます")

                    DisclosureMark(.link)
                }
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .frame(minHeight: 32)
                .tapArea(budgetHintTapOutsets)
            }
            .buttonStyle(.plain)
        }
    }

    var recurringLink: some View {
        Button(action: onOpenRecurrings) {
            ViewThatFits(in: .horizontal) {
                recurringLabel(recurringText(title: "今月の固定費"))

                recurringLabel(recurringText(title: "固定費"))
                    .minimumScaleFactor(0.8)
            }
            .textFont(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                RatioBar(model.output.paidRecurringRatio, tint: Palette.accent)
            }
            .padding(.vertical, 4)
            .tapArea(Self.recurringLinkTapOutsets)
        }
        .buttonStyle(.plain)
    }

    var dialStats: some View {
        HStack(spacing: 0) {
            stat(
                "今日の支出",
                amount: model.output.todayExpense,
                type: .expense
            )

            divider

            stat(
                model.output.middleTitle,
                amount: model.output.middleAmount,
                type: .expense
            )

            divider

            stat(
                "今月の収入",
                amount: model.output.monthIncome,
                type: .income
            )
        }
        .sharesTextScale(id: statAmounts)
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(height: 1)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.accent.opacity(.soft))
            .frame(width: 1, height: 32)
    }

    func recurringLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Label(text, systemImage: "repeat")
                .lineLimit(1)

            DisclosureMark(.link)
        }
    }

    func stat(
        _ title: String,
        amount: Int,
        type: Entry.Kind
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            Group {
                if model.input.list.isFailed {
                    Text(Self.unknownAmount)
                        .foregroundStyle(Palette.subtext)
                } else {
                    AmountText(amount, type: type, font: .size(.body))
                }
            }
            .displayFont(.body)
            .sharedTextScale(floor: 0.5)
            .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }
}

private extension HomeView {
    static let unknownAmount = "—"

    static let recurringLinkTapOutsets = EdgeInsets(
        top: 2,
        leading: 10,
        bottom: 10,
        trailing: 10
    )

    var hasRecurringRow: Bool {
        model.output.recurringExpense > 0
    }

    var budgetLinkTapOutsets: EdgeInsets {
        EdgeInsets(
            top: 10,
            leading: 10,
            bottom: hasRecurringRow ? 2 : 10,
            trailing: 10
        )
    }

    var budgetHintTapOutsets: EdgeInsets {
        EdgeInsets(
            top: 6,
            leading: 0,
            bottom: hasRecurringRow ? 2 : 6,
            trailing: 0
        )
    }

    var dialTitle: String {
        model.output.budgetUsage?.remainingTitle ?? "今月の支出"
    }

    var dialAmount: String {
        guard !model.input.list.isFailed else {
            return Self.unknownAmount
        }

        guard let usage = model.output.budgetUsage else {
            return Yen.text(model.output.monthExpense)
        }

        return usage.remainingAmountText
    }

    var dialProgress: Double? {
        model.input.list.isFailed ? nil : model.output.budgetUsage?.progress
    }

    var dialAmountColor: Color {
        guard !model.input.list.isFailed else {
            return Palette.subtext
        }

        return model.output.budgetUsage?.amountTint ?? Palette.accentStrong
    }

    var statAmounts: [Int] {
        [model.output.todayExpense, model.output.middleAmount, model.output.monthIncome]
    }

    var dialTint: Color {
        model.output.budgetUsage?.tint ?? Palette.accent
    }

    func recurringText(title: String) -> String {
        let total = "\(title) \(Yen.text(model.output.recurringExpense))"
        let upcoming = model.output.upcomingRecurringExpense

        guard upcoming > 0 else {
            return total
        }

        return "\(total)・これから \(Yen.text(upcoming))"
    }
}
