import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var summary: some View {
        HStack(spacing: 0) {
            total("支出", amount: model.expenseTotal, color: Palette.accentStrong)

            total("収入", amount: model.incomeTotal, color: Palette.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card(cornerRadius: 20)
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
                total("支出", amount: summary.expenseTotal, color: Palette.accentStrong)

                total("収入", amount: summary.incomeTotal, color: Palette.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card(cornerRadius: 20)
    }
}

private extension RecordsView {
    func total(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
