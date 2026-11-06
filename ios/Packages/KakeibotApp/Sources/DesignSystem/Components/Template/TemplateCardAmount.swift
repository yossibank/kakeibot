import Core
import SwiftUI

public struct TemplateCardAmount: View {
    @Environment(\.themeStyle) private var themeStyle

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
            AmountText(
                amount,
                font: .fixed(size.amountFont(in: themeStyle)),
                color: Palette.accentStrong
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        } else {
            Text("毎回入れる")
                .font(size.emptyAmountFont(in: themeStyle))
                .foregroundStyle(Palette.hint)
        }
    }
}
