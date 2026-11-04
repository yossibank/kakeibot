import DesignSystem
import SwiftUI

struct SettingsKeypadValue: View {
    let amount: Int
    let isAnimated: Bool

    init(
        _ amount: Int,
        isAnimated: Bool = true
    ) {
        self.amount = amount
        self.isAnimated = isAnimated
    }

    var body: some View {
        Text(AmountText.text(amount))
            .displayFont(.largeTitle, weight: .bold)
            .monospacedDigit()
            .foregroundStyle(Palette.accentStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText())
            .animation(animation, value: amount)
    }
}

private extension SettingsKeypadValue {
    var animation: Animation? {
        isAnimated ? .snappy : nil
    }
}
