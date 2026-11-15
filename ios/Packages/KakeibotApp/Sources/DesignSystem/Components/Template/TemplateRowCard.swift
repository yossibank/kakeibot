import Core
import SwiftUI

public struct TemplateRowCard: View {
    @Environment(\.themeStyle.textFont) private var textFont
    @Environment(\.themeStyle) private var themeStyle

    let icon: Icon?
    let name: String
    let detail: String
    let amount: Int?
    let fit: Fit

    public init(
        icon: Icon?,
        name: String,
        detail: String,
        amount: Int?,
        fit: Fit = .fill
    ) {
        self.icon = icon
        self.name = name
        self.detail = detail
        self.amount = amount
        self.fit = fit
    }

    public var body: some View {
        HStack(spacing: fit.gap) {
            IconTile(icon, size: TemplateBadge.Size.regular.diameter)

            VStack(alignment: .leading, spacing: 4) {
                TemplateCardName(name: name, size: .regular)
                    .lineLimit(fit.nameLines)
                    .minimumScaleFactor(fit.nameScale)

                Text(detail)
                    .font(TemplateCardSize.regular.detailFont(in: themeStyle))
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(width: 0.5, height: fit.dividerHeight)

            TemplateCardAmount(amount: amount, size: .regular)
                .frame(minWidth: fit.amountWidth, alignment: .trailing)
        }
        .padding(.horizontal, fit.padding)
        .frame(maxWidth: fit.maxWidth)
        .frame(height: fit.height)
        .card(cornerRadius: 20)
    }
}

public extension TemplateRowCard {
    enum Fit: Sendable {
        case fill
        case hug
    }
}

public extension TemplateRowCard.Fit {
    var height: CGFloat {
        switch self {
        case .fill: 72
        case .hug: 56
        }
    }
}

private extension TemplateRowCard.Fit {
    var gap: CGFloat {
        switch self {
        case .fill: 12
        case .hug: 8
        }
    }

    var padding: CGFloat {
        switch self {
        case .fill: 16
        case .hug: 12
        }
    }

    var nameLines: Int {
        switch self {
        case .fill: 2
        case .hug: 1
        }
    }

    var nameScale: CGFloat {
        switch self {
        case .fill: 1
        case .hug: 0.8
        }
    }

    var dividerHeight: CGFloat {
        switch self {
        case .fill: 36
        case .hug: 32
        }
    }

    var amountWidth: CGFloat? {
        switch self {
        case .fill: 76
        case .hug: nil
        }
    }

    var maxWidth: CGFloat? {
        switch self {
        case .fill: .infinity
        case .hug: nil
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TemplateRowCard(icon: nil, name: "ランチ", detail: "食費・財布", amount: 980)
        TemplateRowCard(icon: nil, name: "駅前のカフェでモーニング", detail: "食費・財布", amount: 650)
        TemplateRowCard(icon: nil, name: "定期", detail: "交通・銀行", amount: nil)
        TemplateRowCard(icon: nil, name: "ランチ", detail: "食費・財布", amount: 980, fit: .hug)
    }
    .padding()
    .background(Palette.background)
}
