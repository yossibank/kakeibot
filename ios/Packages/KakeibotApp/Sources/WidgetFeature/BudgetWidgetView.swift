import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: BudgetWidgetEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                Palette.background
            }
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
                dial(summary)
            }
        } else {
            Text("アプリを開くと、ここに出ます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    func dial(_ summary: BudgetWidgetSummary) -> some View {
        let usage = summary.usage

        return VStack(spacing: 6) {
            Text(title(of: summary))
                .textFont(size: .caption)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            ZStack(alignment: .bottom) {
                HalfDial(
                    progress: usage?.progress,
                    tint: usage?.tint ?? Palette.accent
                )

                Text(amount(of: summary))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(usage?.amountTint ?? Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .privacySensitive()
            }

            Text(note(of: summary))
                .textFont(size: .caption)
                .monospacedDigit()
                .foregroundStyle(noteColor(of: summary))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .privacySensitive()
        }
    }

    func medium(_ summary: BudgetWidgetSummary) -> some View {
        HStack(spacing: 16) {
            dial(summary)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Palette.line)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows(of: summary)) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .textFont(size: .caption)
                            .foregroundStyle(Palette.subtext)

                        Spacer(minLength: 8)

                        Text(AmountText.text(row.amount))
                            .textFont(size: .body, weight: .medium)
                            .monospacedDigit()
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .privacySensitive()
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension BudgetWidgetView {
    func title(of summary: BudgetWidgetSummary) -> String {
        summary.usage == nil ? "今月の支出" : "今月あといくら"
    }

    func amount(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return AmountText.text(summary.monthExpense)
        }

        return AmountText.text(usage.remaining)
    }

    func note(of summary: BudgetWidgetSummary) -> String {
        let today = "今日 \(AmountText.text(summary.todayExpense))"
        return summary.usage?.warningText ?? today
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

    func rows(of summary: BudgetWidgetSummary) -> [Row] {
        let today = Row(title: "今日", amount: summary.todayExpense)

        guard let usage = summary.usage else {
            return [
                today,
                Row(title: "昨日", amount: summary.yesterdayExpense)
            ]
        }

        return [
            today,
            Row(title: "今月の支出", amount: usage.spent),
            Row(title: "1 日あたり", amount: usage.perDay)
        ]
    }
}
