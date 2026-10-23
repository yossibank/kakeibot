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
            .environment(\.themeStyle, entry.style)
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
                .textFont(.caption)
        }
    }

    @ViewBuilder
    func circular(_ summary: BudgetWidgetSummary) -> some View {
        if let usage = summary.usage,
           !usage.isOver {
            Gauge(value: 1 - usage.progress) {
                Text("あと")
            } currentValueLabel: {
                Text(shortAmount(usage.remaining))
                    .displayFont(.body, weight: .bold)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .privacySensitive()
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 0) {
                    Text(circularTitle(of: summary))
                        .textFont(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(shortAmount(mainAmount(of: summary)))
                        .displayFont(.body, weight: .bold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
                    .textFont(.caption)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let usage = summary.usage {
                    Text("あと \(usage.daysLeft) 日")
                        .textFont(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(AmountText.text(mainAmount(of: summary)))
                .displayFont(.headline, weight: .bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()
                .privacySensitive()

            Text(detail(of: summary))
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .privacySensitive()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inline(_ summary: BudgetWidgetSummary) -> some View {
        let amount = AmountText.text(mainAmount(of: summary))

        return Text("\(inlineTitle(of: summary)) \(amount)")
            .monospacedDigit()
            .privacySensitive()
    }
}

private extension BudgetLockWidgetView {
    nonisolated static let locale = Locale(identifier: "ja_JP")

    func headline(of summary: BudgetWidgetSummary) -> String {
        summary.usage?.remainingTitle ?? "今月の支出"
    }

    func circularTitle(of summary: BudgetWidgetSummary) -> String {
        summary.usage == nil ? "支出" : "オーバー"
    }

    func inlineTitle(of summary: BudgetWidgetSummary) -> String {
        guard let usage = summary.usage else {
            return "今月の支出"
        }

        return usage.isOver ? "予算オーバー" : "今月あと"
    }

    func mainAmount(of summary: BudgetWidgetSummary) -> Int {
        guard let usage = summary.usage else {
            return summary.monthExpense
        }

        return abs(usage.remaining)
    }

    func detail(of summary: BudgetWidgetSummary) -> String {
        let today = summary.today

        return "\(today.title) \(today.text)"
    }

    func shortAmount(_ amount: Int) -> String {
        guard amount >= 10000 else {
            return amount.formatted(.number.locale(Self.locale))
        }

        let man = Double(amount) / 10000

        let format = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(0...1))
            .rounded(rule: .down)
            .locale(Self.locale)

        return "\(man.formatted(format))万"
    }
}
