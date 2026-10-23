import Core
import DesignSystem
import SwiftUI

struct PeriodCard: View {
    let periodText: String
    let month: YearMonth

    var body: some View {
        VStack(spacing: 8) {
            Text("いまの期間")
                .textFont(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            Text(periodText)
                .displayFont(.title)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .contentTransition(.numericText())

            Text("\(month.month)月として数えます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .card(cornerRadius: 24)
        .animation(.snappy, value: periodText)
    }
}
