import DesignSystem
import SwiftUI

struct SettingsKeypadValue: View {
    let amount: Int

    init(_ amount: Int) {
        self.amount = amount
    }

    var body: some View {
        Text(AmountText.text(amount))
            .displayFont(.largeTitle, weight: .bold)
            .monospacedDigit()
            .foregroundStyle(Palette.accentStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText())
            .animation(.snappy, value: amount)
    }
}
