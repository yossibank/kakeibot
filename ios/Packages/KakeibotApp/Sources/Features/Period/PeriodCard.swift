import Core
import DesignSystem
import SwiftUI

struct PeriodCard: View {
    let periodText: String
    let month: YearMonth

    var body: some View {
        VStack(spacing: 6) {
            Text("いまの期間")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.gold)

            Text(periodText)
                .font(.serif(.title))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .contentTransition(.numericText())

            Text("\(month.month)月として数えます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .card(cornerRadius: 22)
        .animation(.snappy, value: periodText)
    }
}
