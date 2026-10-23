import Core
import DesignSystem
import SwiftUI
import WidgetKit

struct BudgetLockWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: BudgetWidgetEntry

    var body: some View {
        content
            .widgetURL(PlannedNotification.Route.home.url)
            .containerBackground(.clear, for: .widget)
    }
}

private extension BudgetLockWidgetView {
    @ViewBuilder
    var content: some View {
        if let summary = entry.summary {
            switch family {
            case .accessoryCircular:
                circular(summary)
            case .accessoryInline:
                inline(summary)
            default:
                rectangular(summary)
            }
        } else if family == .accessoryCircular {
            ZStack {
                AccessoryWidgetBackground()

                Image(systemName: "yensign")
                    .font(.title2)
            }
        } else {
            Text("アプリを開くと出ます")
                .font(.caption)
        }
    }

    @ViewBuilder
    func circular(_ summary: BudgetWidgetSummary) -> some View {
        if let usage = summary.usage {
            Gauge(value: 1 - usage.progress) {
                Text("あと")
            } currentValueLabel: {
                Text(shortAmount(usage.remaining))
                    .monospacedDigit()
                    .privacySensitive()
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 0) {
                    Text("支出")
                        .font(.caption2)

                    Text(shortAmount(summary.monthExpense))
                        .font(.headline)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .privacySensitive()
                }
                .padding(.horizontal, 4)
            }
        }
    }

    func rectangular(_ summary: BudgetWidgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(headline(of: summary))
                    .font(.caption)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let usage = summary.usage {
                    Text("あと \(usage.daysLeft) 日")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(AmountText.text(mainAmount(of: summary)))
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()
                .privacySensitive()

            Text(detail(of: summary))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .privacySensitive()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inline(_ summary: BudgetWidgetSummary) -> some View {
        let label = summary.usage == nil ? "今月の支出" : "今月あと"
        let amount = AmountText.text(mainAmount(of: summary))

        return Text("\(label) \(amount)")
            .monospacedDigit()
            .privacySensitive()
    }
}

private extension BudgetLockWidgetView {
    nonisolated static let locale = Locale(identifier: "ja_JP")

    func headline(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return "今月の支出"
        }

        return usage.isOver ? "予算を超えています" : "今月あといくら"
    }

    func mainAmount(of summary: BudgetWidgetSummary) -> Int {
        summary.usage?.remaining ?? summary.monthExpense
    }

    func detail(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return "今日の支出 \(AmountText.text(summary.todayExpense))"
        }

        let left = usage.todayRemaining(spentToday: summary.todayExpense)

        return "今日あと \(AmountText.text(left))"
    }

    func shortAmount(_ amount: Int) -> String {
        let sign = amount < 0 ? "−" : ""
        let value = abs(amount)

        guard value >= 10000 else {
            return "\(sign)\(value.formatted(.number.locale(Self.locale)))"
        }

        let man = Double(value) / 10000

        let format = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(0...1))
            .rounded(rule: .down)
            .locale(Self.locale)

        return "\(sign)\(man.formatted(format))万"
    }
}
