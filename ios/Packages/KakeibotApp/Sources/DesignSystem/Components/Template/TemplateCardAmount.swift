import Core
import SwiftUI

public struct TemplateCardAmount: View {
    @Environment(\.themeStyle.font) private var themeFont

    let amount: Int?
    let size: TemplateCardSize

    public init(
        amount: Int?,
        size: TemplateCardSize
    ) {
        self.amount = amount
        self.size = size
    }

    public var body: some View {
        if let amount {
            Text(AmountText.text(amount))
                .font(size.amountFont(in: themeFont))
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Text("毎回入れる")
                .font(size.emptyAmountFont(in: themeFont))
                .foregroundStyle(Palette.hint)
        }
    }
}
