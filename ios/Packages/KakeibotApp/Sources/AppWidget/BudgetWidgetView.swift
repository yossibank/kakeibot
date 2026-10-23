import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: BudgetWidgetEntry

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(PlannedNotification.Route.home.url)
            .widgetTheme(entry.look)
    }
}

private extension BudgetWidgetView {
    struct Row: Identifiable {
        let title: String
        let amount: Int

        var id: String {
            title
        }
    }

    @ViewBuilder
    var content: some View {
        if let summary = entry.summary {
            switch family {
            case .systemMedium:
                medium(summary)
            default:
                small(summary)
            }
        } else {
            Text("アプリを開くと、ここに出ます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    func small(_ summary: BudgetWidgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                title(of: summary)
                Spacer(minLength: 4)
                days(of: summary)
            }

            Spacer(minLength: 4)
            dial(summary)
            Spacer(minLength: 6)
            footer(of: summary)
        }
    }

    func medium(_ summary: BudgetWidgetSummary) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                title(of: summary)
                Spacer(minLength: 4)
                dial(summary)
                Spacer(minLength: 6)

                Text(budgetNote(of: summary))
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(noteColor(of: summary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .privacySensitive()
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                let today = summary.today

                HStack(alignment: .firstTextBaseline) {
                    Text(today.title)
                        .textFont(size: .caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 4)
                    days(of: summary)
                }

                Text(today.text)
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(todayColor(today, otherwise: Palette.accentStrong))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .privacySensitive()

                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)
                    .padding(.vertical, 12)

                VStack(spacing: 8) {
                    ForEach(rows(of: summary)) { row in
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.title)
                                .textFont(size: .caption)
                                .foregroundStyle(Palette.subtext)

                            Spacer(minLength: 8)

                            Text(AmountText.text(row.amount))
                                .textFont(size: .small, weight: .medium)
                                .monospacedDigit()
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .privacySensitive()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

    func title(of summary: BudgetWidgetSummary) -> some View {
        Text(titleText(of: summary))
            .textFont(size: .caption)
            .tracking(1)
            .foregroundStyle(Palette.accent)
            .lineLimit(1)
    }

    @ViewBuilder
    func days(of summary: BudgetWidgetSummary) -> some View {
        if let usage = summary.usage {
            Text("あと \(usage.daysLeft) 日")
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)
        }
    }

    func dial(_ summary: BudgetWidgetSummary) -> some View {
        let usage = summary.usage

        return ZStack(alignment: .bottom) {
            HalfDial(
                progress: usage?.progress,
                tint: usage?.tint ?? Palette.accent
            )

            Text(amount(of: summary))
                .displayFont(.title, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(amountColor(of: summary))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 28)
                .privacySensitive()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func footer(of summary: BudgetWidgetSummary) -> some View {
        if let warning = summary.usage?.warningText {
            Text(warning)
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(noteColor(of: summary))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        } else {
            let today = summary.today

            HStack(alignment: .firstTextBaseline) {
                Text(today.title)
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 4)

                Text(today.text)
                    .textFont(size: .small, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(todayColor(today, otherwise: Palette.text))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .privacySensitive()
            }
        }
    }
}

private extension BudgetWidgetView {
    func titleText(of summary: BudgetWidgetSummary) -> String {
        summary.usage == nil ? "今月の支出" : "今月あといくら"
    }

    func amount(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return AmountText.text(summary.monthExpense)
        }

        return AmountText.text(usage.remaining)
    }

    func amountColor(of summary: BudgetWidgetSummary) -> Color {
        summary.usage?.amountTint ?? Palette.accentStrong
    }

    func budgetNote(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return "予算は決めていません"
        }

        return usage.warningText ?? "予算 \(AmountText.text(usage.budget))"
    }

    func noteColor(of summary: BudgetWidgetSummary) -> Color {
        guard
            let usage = summary.usage,
            usage.warningText != nil
        else {
            return Palette.subtext
        }

        return usage.tint
    }

    func todayColor(
        _ today: BudgetWidgetSummary.Today,
        otherwise color: Color
    ) -> Color {
        today.isOver ? Palette.rose : color
    }

    func rows(of summary: BudgetWidgetSummary) -> [Row] {
        guard let usage = summary.usage else {
            return [Row(title: "昨日の支出", amount: summary.yesterdayExpense)]
        }

        return [
            Row(title: "今日の支出", amount: summary.todayExpense),
            Row(title: "今月の支出", amount: usage.spent)
        ]
    }
}
