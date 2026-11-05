import DesignSystem
import SwiftUI

struct WhatsNewIconScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .iconButton:
            iconButton
                .whatsNewTapped()

        case .iconGrid:
            grid

        default:
            row
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewIconScene {
    static let symbols = [
        ["figure.climbing", "film.stack", "dryer"],
        ["giftcard", "play.rectangle", "figure.bowling"]
    ]

    static let emojis = ["🍚", "🍗", "🌮", "🍲"]

    var row: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .foregroundStyle(Palette.accent)

            Text("カテゴリ")
                .foregroundStyle(Palette.text)

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .foregroundStyle(Palette.hint)
        }
        .textFont(size: .caption, weight: .semibold)
        .padding(.horizontal, 12)
        .frame(height: 40)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var iconButton: some View {
        Image(systemName: "fork.knife")
            .font(.system(size: 30))
            .foregroundStyle(Palette.accent)
            .frame(width: 64, height: 64)
            .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 16))
    }

    var grid: some View {
        VStack(spacing: 8) {
            ForEach(Self.symbols, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.accentStrong)
                            .frame(width: 32, height: 32)
                    }
                }
            }

            HStack(spacing: 4) {
                ForEach(Self.emojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 18))
                        .frame(width: 26, height: 26)
                }
            }
        }
        .padding(8)
        .card(cornerRadius: 12)
    }
}
