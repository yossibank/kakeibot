import Core
import DesignSystem
import SwiftUI

public struct PeriodRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let model: HomeModel
    private let onOpenRecurring: (Recurring.ID) -> Void

    public init(
        model: HomeModel,
        onOpenRecurring: @escaping (Recurring.ID) -> Void
    ) {
        self.model = model
        self.onOpenRecurring = onOpenRecurring
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    summaryCard
                    timelineCard
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .padding(.horizontal, -18)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension PeriodRecurringSheet {
    var header: some View {
        ZStack {
            Text("今月の固定費")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            HStack {
                RingButton(systemImage: "xmark") {
                    dismiss()
                }

                Spacer()
            }
        }
    }

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.monthRangeText)
                .textFont(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("これから出ていく")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(model.upcomingRecurringExpense))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }

            progressBar

            HStack(spacing: 0) {
                stat(
                    "支払った",
                    amount: model.paidRecurringExpense,
                    type: .expense
                )

                divider

                stat(
                    "支出の合計",
                    amount: model.recurringExpense,
                    type: .expense
                )

                divider

                stat(
                    "収入の合計",
                    amount: model.recurringIncome,
                    type: .income
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.faint)

                Capsule()
                    .fill(Palette.accent)
                    .frame(width: proxy.size.width * model.paidRecurringRatio)
            }
        }
        .frame(height: 6)
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 28)
    }

    var timelineCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                if index == todayIndex {
                    todayMarker
                }

                VStack(spacing: 0) {
                    Button {
                        onOpenRecurring(item.recurring.id)
                    } label: {
                        row(item)
                    }
                    .buttonStyle(.plain)

                    if item.status == .missing {
                        recordButton(item)
                    }
                }
            }

            if todayIndex == items.count {
                todayMarker
            }
        }
        .padding(.vertical, 6)
        .card()
    }

    var todayMarker: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Palette.accent.opacity(.muted))
                .frame(height: 1)

            Text("今日 \(model.today.month)/\(model.today.day)")
                .textFont(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            Rectangle()
                .fill(Palette.accent.opacity(.muted))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    func stat(
        _ title: String,
        amount: Int,
        type: Entry.Kind
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            AmountText(amount, type: type)
                .textFont(.subheadline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    func row(_ item: HomeModel.PeriodRecurring) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text("\(item.date.day)")
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)

                Text(item.date.weekday.shortName)
                    .textFont(.caption2)
                    .foregroundStyle(Self.weekdayTint(item.date))
            }
            .frame(width: 30)

            IconBadge(model.icon(of: item.recurring), size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.title(of: item.recurring))
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                if let place = model.place(of: item.recurring) {
                    Text(place)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                AmountText(item.amount, type: item.recurring.type)
                    .textFont(.subheadline)

                statusLabel(item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(Self.opacity(of: item.status))
        .contentShape(.rect)
    }

    func recordButton(_ item: HomeModel.PeriodRecurring) -> some View {
        Button {
            Task {
                await model.record(item)
            }
        } label: {
            Label("この日の分を記録", systemImage: "plus")
                .textFont(.caption)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Palette.faint, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func statusLabel(_ item: HomeModel.PeriodRecurring) -> some View {
        switch item.status {
        case .done:
            Label("済み", systemImage: "checkmark")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
        case .upcoming:
            Text(daysText(until: item.date))
                .textFont(.caption2)
                .foregroundStyle(Palette.accent)
        case .missing:
            Label("記録がありません", systemImage: "exclamationmark.circle")
                .textFont(.caption2)
                .foregroundStyle(Palette.amber)
        }
    }
}

private extension PeriodRecurringSheet {
    var items: [HomeModel.PeriodRecurring] {
        model.periodRecurrings
    }

    var todayIndex: Int {
        items.firstIndex { $0.date > model.today } ?? items.count
    }

    static func weekdayTint(_ date: LocalDate) -> Color {
        if Holiday.contains(date) {
            return Palette.holiday
        }

        return date.weekday.tint ?? Palette.subtext
    }

    static func opacity(of status: HomeModel.Status) -> Double {
        status == .done ? 0.5 : 1
    }

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }
}
