import Core
import DesignSystem
import SwiftUI

public struct UpcomingRecurringSheet: View {
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

                    ForEach(model.upcomingRecurrings, id: \.self) { item in
                        Button {
                            onOpenRecurring(item.recurring.id)
                        } label: {
                            row(item)
                        }
                        .buttonStyle(.plain)
                    }

                    totalRow
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

private extension UpcomingRecurringSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("これからの固定費")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            RingButton(systemImage: "list.bullet", label: "すべて") {
                onOpenAll()
            }
        }
    }

    var totalRow: some View {
        HStack {
            Text("合計")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            Spacer()

            AmountText(model.upcomingRecurringExpense, type: .expense)
                .textFont(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    func row(_ item: HomeModel.UpcomingRecurring) -> some View {
        HStack(spacing: 12) {
            Text("\(item.date.month)/\(item.date.day)")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
                .frame(width: 48, alignment: .leading)

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
        .contentShape(.rect)
    }
}
