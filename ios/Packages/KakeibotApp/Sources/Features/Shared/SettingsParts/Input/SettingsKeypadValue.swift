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
        AmountText(amount, font: .size(.largeTitle, weight: .bold), color: Palette.accentStrong)
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
