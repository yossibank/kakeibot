import Core
import DesignSystem
import SwiftUI

struct RecurringLoanPlan: View {
    let total: Int
    let endDate: LocalDate

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("返す総額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(total))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text("終わり")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text("\(endDate.year)年\(endDate.month)月")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)
            }
        }
        .padding(16)
        .card()
    }
}
