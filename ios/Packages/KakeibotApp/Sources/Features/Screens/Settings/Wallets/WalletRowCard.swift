import Core
import DesignSystem
import SwiftUI

struct WalletRowCard<Leading: View>: View {
    let name: String
    let kind: Wallet.Kind
    let amount: Int
    let caption: String?
    let icon: Leading

    init(
        name: String,
        kind: Wallet.Kind,
        amount: Int,
        caption: String? = nil,
        @ViewBuilder icon: () -> Leading
    ) {
        self.name = name
        self.kind = kind
        self.amount = amount
        self.caption = caption
        self.icon = icon()
    }

    var body: some View {
        HStack(spacing: 16) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                Text(kind.title)
                    .textFont(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let caption {
                    Text(caption)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }

                Text(AmountText.text(amount))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Self.height)
        .card(cornerRadius: 20)
    }
}

extension WalletRowCard {
    static var height: CGFloat {
        68
    }
}

private extension WalletRowCard {
    var amountColor: Color {
        amount < 0 ? Palette.rose : Palette.accentStrong
    }
}

struct WalletRowIcon: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?
    var stroke: Color = Palette.accent.opacity(.muted)
    var strokeWidth: CGFloat = 1

    var body: some View {
        IconImage(icon, size: 18)
            .foregroundStyle(Palette.accent)
            .frame(width: 40, height: 40)
            .background(
                Palette.accent.opacity(.subtle),
                in: .rect(cornerRadius: corner.radius(12))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(12))
                    .stroke(stroke, lineWidth: strokeWidth)
            }
    }
}
