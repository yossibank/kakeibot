import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var summary: some View {
        totals(expense: model.expenseTotal, income: model.incomeTotal)
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

            totals(expense: summary.expenseTotal, income: summary.incomeTotal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card()
    }
}

private extension RecordsView {
    var totalDivider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    func totals(
        expense: Int,
        income: Int
    ) -> some View {
        VStack(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                totalsRow(expense: expense, income: income, isStacked: false)
                totalsRow(expense: expense, income: income, isStacked: true)
            }

            Hairline(thickness: 1)

            balanceRow(income - expense)
        }
    }

    func balanceRow(_ balance: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(ReviewText.balanceTitle(balance))
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize()

            Spacer(minLength: 8)

            AmountText(
                balance,
                font: .style(.subheadline, weight: .semibold),
                sign: .plus,
                color: ReviewText.balanceColor(balance)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    func totalsRow(
        expense: Int,
        income: Int,
        isStacked: Bool
    ) -> some View {
        HStack(spacing: 12) {
            total("支出", amount: expense, type: .expense, isStacked: isStacked)

            totalDivider

            total("収入", amount: income, type: .income, isStacked: isStacked)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    func total(
        _ title: String,
        amount: Int,
        type: Entry.Kind,
        isStacked: Bool
    ) -> some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))

        return layout {
            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .fixedSize()

            AmountText(amount, type: type, font: .size(.body))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
