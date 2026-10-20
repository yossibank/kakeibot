import Core
import DesignSystem
import SwiftUI

public struct PeriodRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let model: HomeModel
    private let onOpenRecurring: (Recurring.ID) -> Void
    private let onOpenAll: () -> Void

    public init(
        model: HomeModel,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenAll: @escaping () -> Void
    ) {
        self.model = model
        self.onOpenRecurring = onOpenRecurring
        self.onOpenAll = onOpenAll
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle(model.monthRangeText)

                    ForEach(model.periodRecurrings, id: \.self) { item in
                        Button {
                            onOpenRecurring(item.recurring.id)
                        } label: {
                            row(item)
                        }
                        .buttonStyle(.plain)
                    }

                    totals
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
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("今月の固定費")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            RingButton(systemImage: "list.bullet", label: "すべて") {
                onOpenAll()
            }
        }
    }

    var totals: some View {
        VStack(spacing: 6) {
            totalRow("支出の合計", amount: model.recurringExpense)
            totalRow("これから", amount: model.upcomingRecurringExpense)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    func totalRow(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(title)
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            Spacer()

            AmountText(amount, type: .expense)
                .textFont(.subheadline)
        }
    }

    func row(_ item: HomeModel.PeriodRecurring) -> some View {
        HStack(spacing: 12) {
            Text(Self.dateText(item.date))
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
                .frame(width: 76, alignment: .leading)

            Text(model.title(of: item.recurring))
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)

            Spacer()

            AmountText(item.recurring.amount, type: item.recurring.type)
                .textFont(.subheadline)

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .card()
        .opacity(Self.opacity(isDone: item.isDone))
        .contentShape(.rect)
    }
}

private extension PeriodRecurringSheet {
    static func dateText(_ date: LocalDate) -> String {
        "\(date.month)/\(date.day)（\(date.weekday.shortName)）"
    }

    static func opacity(isDone: Bool) -> Double {
        isDone ? 0.45 : 1
    }
}
