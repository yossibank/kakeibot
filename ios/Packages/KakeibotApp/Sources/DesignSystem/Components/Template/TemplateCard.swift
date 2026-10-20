import Core
import SwiftUI

public struct TemplateCard<Name: View, Amount: View>: View {
    @Environment(\.themeStyle.textFont) private var textFont

    let icon: Icon?
    let detail: String
    let size: TemplateCardSize
    let name: Name
    let amount: Amount

    public init(
        icon: Icon?,
        detail: String,
        size: TemplateCardSize = .regular,
        @ViewBuilder name: () -> Name,
        @ViewBuilder amount: () -> Amount
    ) {
        self.icon = icon
        self.detail = detail
        self.size = size
        self.name = name()
        self.amount = amount()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: size.spacing) {
            HStack(spacing: size.gap) {
                TemplateBadge(icon: icon, size: size)

                VStack(alignment: .leading, spacing: size.textSpacing) {
                    name
                        .lineLimit(size.nameLines)

                    Text(detail)
                        .font(size.detailFont(in: textFont))
                        .tracking(1)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(height: 0.5)

            amount
                .frame(
                    maxWidth: .infinity,
                    minHeight: size.amountHeight,
                    maxHeight: size.amountHeight,
                    alignment: .leading
                )
        }
        .padding(.horizontal, size.padding)
        .frame(maxWidth: .infinity)
        .frame(height: size.height)
        .templateCardFace(
            cornerRadius: size.cornerRadius,
            shadowRadius: size.shadowRadius
        )
    }
}

public extension TemplateCard
    where Name == TemplateCardName, Amount == TemplateCardAmount {
    init(
        icon: Icon?,
        name: String,
        detail: String,
        amount: Int?,
        size: TemplateCardSize = .regular
    ) {
        self.init(icon: icon, detail: detail, size: size) {
            TemplateCardName(name: name, size: size)
        } amount: {
            TemplateCardAmount(amount: amount, size: size)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TemplateCard(
            icon: nil,
            name: "ランチ",
            detail: "食費・財布",
            amount: 980,
            size: .large
        )

        HStack(spacing: 8) {
            TemplateCard(
                icon: nil,
                name: "コーヒー",
                detail: "カフェ・財布",
                amount: 450
            )

            TemplateCard(
                icon: nil,
                name: "定期",
                detail: "交通・銀行",
                amount: nil
            )
        }
    }
    .padding()
    .background(Palette.background)
}
