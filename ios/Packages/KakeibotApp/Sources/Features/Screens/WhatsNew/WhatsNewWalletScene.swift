import Core
import DesignSystem
import SwiftUI

struct WhatsNewWalletScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .walletKinds:
            kinds

        case .walletMade:
            debtCard(isMade: true)

        default:
            debtCard(isMade: false)
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewWalletScene {
    static let debtKinds: [Wallet.Kind] = [.card, .loan]

    var kinds: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手持ち")
                .textFont(size: .micro, weight: .bold)
                .foregroundStyle(Palette.hint)

            VStack(alignment: .leading, spacing: 4) {
                Text("後で払う・返す")
                    .textFont(size: .micro, weight: .bold)
                    .foregroundStyle(Palette.text)

                HStack(spacing: 4) {
                    ForEach(Self.debtKinds, id: \.self) { kind in
                        kindChip(kind)
                    }
                }
            }

            Text("値動きがある")
                .textFont(size: .micro, weight: .bold)
                .foregroundStyle(Palette.hint)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var walletRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "creditcard")
                .foregroundStyle(Palette.accent)

            Text("カード")
                .foregroundStyle(Palette.text)

            Spacer(minLength: 2)

            AmountText(0, font: .size(.micro, weight: .semibold), color: Palette.text)
        }
        .textFont(size: .micro, weight: .semibold)
        .monospacedDigit()
        .frame(height: 24)
    }

    var addRow: some View {
        let shape = RoundedRectangle(cornerRadius: 4)

        return HStack(spacing: 4) {
            shape
                .fill(Palette.faint)
                .overlay {
                    shape
                        .stroke(Palette.outline, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .overlay {
                    Image(systemName: "plus")
                        .textFont(size: .micro, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                }
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text("新しい口座を追加")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)

                Text("カード・借入")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    func kindChip(_ kind: Wallet.Kind) -> some View {
        let isSelected = kind == .card
        let textColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)

        return Text(kind.title)
            .textFont(size: .micro, weight: .semibold)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .background(fill, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(stroke, lineWidth: 1)
            }
    }

    func debtCard(isMade: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("負債")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            if isMade {
                walletRow
            }

            addRow
        }
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }
}
