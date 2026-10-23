import Core
import DesignSystem
import Store
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
        if let overview = entry.overview {
            switch family {
            case .systemMedium:
                medium(overview)
            default:
                dial(overview)
            }
        } else {
            Text("アプリを開くと、ここに出ます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
    }

    func dial(_ overview: MonthOverview) -> some View {
        let usage = overview.budgetUsage

        return VStack(spacing: 6) {
            Text(title(of: overview))
                .textFont(size: .caption)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            ZStack(alignment: .bottom) {
                HalfDial(
                    progress: usage?.progress,
                    tint: usage?.tint ?? Palette.accent
                )

                Text(amount(of: overview))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(usage?.amountTint ?? Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .privacySensitive()
            }

            Text(note(of: overview))
                .textFont(size: .caption)
                .monospacedDigit()
                .foregroundStyle(noteColor(of: overview))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .privacySensitive()
        }
    }

    func medium(_ overview: MonthOverview) -> some View {
        HStack(spacing: 16) {
            dial(overview)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Palette.line)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows(of: overview)) { row in
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
    func title(of overview: MonthOverview) -> String {
        overview.budgetUsage == nil ? "今月の支出" : "今月あといくら"
    }

    func amount(of overview: MonthOverview) -> String {
        guard let usage = overview.budgetUsage else {
            return AmountText.text(overview.monthExpense)
        }

        return AmountText.text(usage.remaining)
    }

    func note(of overview: MonthOverview) -> String {
        let today = "今日 \(AmountText.text(overview.todayExpense))"
        return overview.budgetUsage?.warningText ?? today
    }

    func noteColor(of overview: MonthOverview) -> Color {
        guard
            let usage = overview.budgetUsage,
            usage.warningText != nil
        else {
            return Palette.subtext
        }

        return usage.tint
    }

    func rows(of overview: MonthOverview) -> [Row] {
        let today = Row(title: "今日", amount: overview.todayExpense)

        guard let usage = overview.budgetUsage else {
            return [
                today,
                Row(title: "昨日", amount: overview.yesterdayExpense)
            ]
        }

        return [
            today,
            Row(title: "今月の支出", amount: usage.spent),
            Row(title: "1 日あたり", amount: usage.perDay)
        ]
    }
}
