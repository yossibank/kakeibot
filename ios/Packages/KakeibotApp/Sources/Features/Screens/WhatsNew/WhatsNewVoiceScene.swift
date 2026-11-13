import DesignSystem
import SwiftUI

struct WhatsNewVoiceScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .voiceListen:
            listen

        case .voiceFilled:
            filled

        default:
            amountRow
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewVoiceScene {
    static let bars: [CGFloat] = [4, 8, 14, 22, 30, 22, 26, 16, 10, 6, 4]

    var amountRow: some View {
        HStack(spacing: 4) {
            Text("金額")
                .textFont(size: .micro, weight: .semibold)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 2)

            circle("doc.text.viewfinder")

            circle("mic")
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var listen: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(Self.bars.indices, id: \.self) { index in
                    Capsule()
                        .fill(Palette.accent)
                        .frame(width: 3, height: Self.bars[index])
                }
            }
            .frame(height: 32)

            Text("ランチ 980円\nカードで")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var filled: some View {
        VStack(spacing: 0) {
            row("カテゴリ", value: "食費")

            Hairline()

            row("支払い元", value: "カード")

            Hairline()

            HStack(spacing: 4) {
                Text("金額")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 2)

                AmountText(980, font: .size(.headline, weight: .bold), color: Palette.accentStrong)
            }
            .frame(height: 32)
        }
        .padding(.horizontal, 8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func circle(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .textFont(size: .caption, weight: .semibold)
            .foregroundStyle(Palette.accent)
            .frame(width: 26, height: 26)
            .overlay {
                Circle()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
    }

    func row(
        _ label: String,
        value: String
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 2)

            Text(value)
                .foregroundStyle(Palette.text)
                .underline(color: Palette.accent.opacity(.medium))
        }
        .textFont(size: .micro, weight: .semibold)
        .frame(height: 28)
    }
}
