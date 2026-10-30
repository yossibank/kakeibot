import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var dialCard: some View {
        VStack(spacing: 16) {
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
            .animation(.snappy, value: model.budgetUsage)

            VStack(spacing: 4) {
                if let usage = model.budgetUsage {
                    VStack(spacing: 4) {
                        if !model.isListFailed,
                           let warning = usage.warningText {
                            Text(warning)
                                .textFont(.caption, weight: .semibold)
                                .foregroundStyle(usage.tint)
                        }

                        Button {
                            onOpenSetup(.budget)
                        } label: {
                            HStack(spacing: 4) {
                                Text("予算 \(AmountText.text(usage.budget))")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
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

                            Image(systemName: "chevron.right")
                                .sansFont(.micro, weight: .semibold)
                        }
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .frame(minHeight: 32)
                        .tapArea(budgetHintTapOutsets)
                    }
                    .buttonStyle(.plain)
                }

                if hasRecurringRow {
                    Button(action: onOpenRecurrings) {
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Label(recurringText, systemImage: "repeat")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)

                            RatioBar(model.paidRecurringRatio, tint: Palette.accent)
                        }
                        .padding(.vertical, 4)
                        .tapArea(Self.recurringLinkTapOutsets)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 0) {
                stat(
                    "今日の支出",
                    amount: model.todayExpense,
                    type: .expense
                )

                divider

                stat(
                    model.middleTitle,
                    amount: model.middleAmount,
                    type: .expense
                )

                divider

                stat(
                    "今月の収入",
                    amount: model.monthIncome,
                    type: .income
                )
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.accent.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .padding(.top, 4)
        .card()
    }
}

private extension HomeView {
    var divider: some View {
        Rectangle()
            .fill(Palette.accent.opacity(.soft))
            .frame(width: 1, height: 32)
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
                if model.isListFailed {
                    Text(Self.unknownAmount)
                        .foregroundStyle(Palette.subtext)
                } else {
                    AmountText(amount, type: type)
                }
            }
            .displayFont(.body)
            .lineLimit(1)
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
        model.recurringExpense > 0
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
        model.budgetUsage?.remainingTitle ?? "今月の支出"
    }

    var dialAmount: String {
        guard !model.isListFailed else {
            return Self.unknownAmount
        }

        guard let usage = model.budgetUsage else {
            return AmountText.text(model.monthExpense)
        }

        return usage.remainingAmountText
    }

    var dialProgress: Double? {
        model.isListFailed ? nil : model.budgetUsage?.progress
    }

    var dialAmountColor: Color {
        guard !model.isListFailed else {
            return Palette.subtext
        }

        return model.budgetUsage?.amountTint ?? Palette.accentStrong
    }

    var recurringText: String {
        let total = "今月の固定費 \(AmountText.text(model.recurringExpense))"
        let upcoming = model.upcomingRecurringExpense

        guard upcoming > 0 else {
            return total
        }

        return "\(total)・これから \(AmountText.text(upcoming))"
    }

    var dialTint: Color {
        model.budgetUsage?.tint ?? Palette.accent
    }
}
