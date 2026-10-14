import Core
import SwiftUI

public struct TemplateCard<Name: View, Amount: View>: View {
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
                IconImage(icon, size: size.iconSize)
                    .foregroundStyle(Palette.gold)
                    .frame(width: size.badgeSize, height: size.badgeSize)
                    .background(Palette.gold.opacity(0.06), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Self.foil, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    name
                        .lineLimit(1)

                    Text(detail)
                        .font(size.detailFont)
                        .tracking(1)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }
            }

            Rectangle()
                .fill(Palette.gold.opacity(0.18))
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
        .background {
            ZStack {
                Self.shape(size)
                    .fill(Self.fill)

                Self.shape(size)
                    .fill(Self.gloss)
            }
        }
        .overlay {
            Self.shape(size)
                .strokeBorder(Self.foil, lineWidth: 1.2)
        }
        .overlay {
            Self.shape(size)
                .inset(by: 4)
                .strokeBorder(Palette.gold.opacity(0.1), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
        .shadow(
            color: .black.opacity(0.55),
            radius: size.shadowRadius,
            y: size.shadowRadius * 0.7
        )
    }
}

public extension TemplateCard where Name == Text, Amount == TemplateCardAmount {
    init(
        icon: Icon?,
        name: String,
        detail: String,
        amount: Int?,
        size: TemplateCardSize = .regular
    ) {
        self.init(icon: icon, detail: detail, size: size) {
            Text(name)
                .font(size.nameFont)
                .foregroundStyle(Palette.champagne)
        } amount: {
            TemplateCardAmount(amount: amount, size: size)
        }
    }
}

private extension TemplateCard {
    static var fill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var gloss: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.08), .white.opacity(0)],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    static var foil: AngularGradient {
        AngularGradient(
            colors: [
                Palette.champagne.opacity(0.9),
                Palette.gold.opacity(0.6),
                Palette.bronze.opacity(0.5),
                Palette.gold.opacity(0.6),
                Palette.champagne.opacity(0.9)
            ],
            center: .center
        )
    }

    static func shape(_ size: TemplateCardSize) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: size.cornerRadius)
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
    .background(Palette.night)
}
