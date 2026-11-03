import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var summary: some View {
        HStack(spacing: 0) {
            total("支出", amount: model.expenseTotal, type: .expense)

            total("収入", amount: model.incomeTotal, type: .income)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card()
    }

    func searchSummary(_ summary: RecordsModel.SearchSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(summary.count) 件")
                    .textFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                selectButton

                Spacer()

                Text(PeriodText.range(summary.range, today: model.today))
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            HStack(spacing: 0) {
                total("支出", amount: summary.expenseTotal, type: .expense)

                total("収入", amount: summary.incomeTotal, type: .income)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card()
    }
}

private extension RecordsView {
    func total(
        _ title: String,
        amount: Int,
        type: Entry.Kind
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            AmountText(amount, type: type)
                .displayFont(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
