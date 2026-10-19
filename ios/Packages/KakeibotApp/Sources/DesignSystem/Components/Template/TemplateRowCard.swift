import Core
import SwiftUI

public struct TemplateRowCard: View {
    let icon: Icon?
    let name: String
    let detail: String
    let amount: Int?

    public init(
        icon: Icon?,
        name: String,
        detail: String,
        amount: Int?
    ) {
        self.icon = icon
        self.name = name
        self.detail = detail
        self.amount = amount
    }

    public var body: some View {
        HStack(spacing: 12) {
            TemplateBadge(icon: icon, size: .regular)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(TemplateCardSize.regular.nameFont)
                    .foregroundStyle(Palette.accentLight)
                    .lineLimit(2)

                Text(detail)
                    .font(TemplateCardSize.regular.detailFont)
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(width: 0.5, height: 36)

            TemplateCardAmount(amount: amount, size: .regular)
                .frame(minWidth: 76, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .templateCardFace(cornerRadius: 18, shadowRadius: 8)
    }
}

public extension TemplateRowCard {
    static let height: CGFloat = 72
}

#Preview {
    VStack(spacing: 10) {
        TemplateRowCard(
            icon: nil,
            name: "ランチ",
            detail: "食費・財布",
            amount: 980
        )

        TemplateRowCard(
            icon: nil,
            name: "駅前のカフェでモーニング",
            detail: "食費・財布",
            amount: 650
        )

        TemplateRowCard(
            icon: nil,
            name: "定期",
            detail: "交通・銀行",
            amount: nil
        )
    }
    .padding()
    .background(Palette.background)
}
