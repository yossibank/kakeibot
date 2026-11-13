import DesignSystem
import SwiftUI

struct WhatsNewEntryScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .entryDeck:
            deck

        case .entryShortcuts:
            shortcuts

        default:
            slip
        }
    }
}

private extension WhatsNewEntryScene {
    struct Shortcut {
        let systemImage: String
        let name: String
        let detail: String
        let amount: Int
    }

    static let keys = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"]
    ]

    static let shortcuts = [
        Shortcut(systemImage: "fork.knife", name: "ランチ", detail: "食費・財布", amount: 900),
        Shortcut(systemImage: "tram.fill", name: "電車", detail: "交通・財布", amount: 440)
    ]

    var slip: some View {
        VStack(spacing: 0) {
            row("カテゴリ", value: "食費")

            Hairline()

            row("支払い元", value: "財布")

            Hairline()

            row("日付", value: "今日")

            Hairline()

            HStack(spacing: 4) {
                Text("金額")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 2)

                AmountText(1280, font: .size(.headline, weight: .bold), color: Palette.accentStrong)
            }
            .frame(height: 32)
        }
        .padding(.horizontal, 8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var deck: some View {
        VStack(spacing: 4) {
            ForEach(Self.keys, id: \.self) { line in
                HStack(spacing: 4) {
                    ForEach(line, id: \.self) { key in
                        Text(key)
                            .textFont(size: .small, weight: .semibold)
                            .foregroundStyle(Palette.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 26)
                            .card(cornerRadius: 8)
                    }
                }
            }

            Text("保存")
                .textFont(size: .caption, weight: .bold)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .goldFace()
        }
        .padding(.horizontal, 8)
    }

    var shortcuts: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("テンプレート")
                .textFont(size: .micro, weight: .bold)
                .foregroundStyle(Palette.subtext)

            ForEach(Self.shortcuts, id: \.name) { shortcut in
                card(shortcut)
            }
        }
        .padding(.horizontal, 4)
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
        }
        .textFont(size: .micro, weight: .semibold)
        .frame(height: 24)
    }

    func card(_ shortcut: Shortcut) -> some View {
        HStack(spacing: 4) {
            Image(systemName: shortcut.systemImage)
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: 24, height: 24)
                .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 0) {
                Text(shortcut.name)
                    .textFont(size: .caption, weight: .bold)
                    .foregroundStyle(Palette.text)

                HStack(spacing: 4) {
                    Text(shortcut.detail)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 2)

                    AmountText(
                        shortcut.amount,
                        font: .size(.micro, weight: .semibold),
                        color: Palette.accentStrong
                    )
                }
                .textFont(size: .micro)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .card(cornerRadius: 12)
    }
}
