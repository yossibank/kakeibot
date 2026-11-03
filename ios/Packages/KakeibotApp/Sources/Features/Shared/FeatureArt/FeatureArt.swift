import Core
import DesignSystem
import SwiftUI

struct FeatureArt: View {
    @Environment(\.themeStyle.corner) private var corner

    let kind: Kind

    var body: some View {
        FeatureArtCanvas(width: Self.width, height: Self.height) {
            content
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Palette.faint, in: .rect(cornerRadius: corner.radius(16)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(16))
                .stroke(Palette.hairline, lineWidth: 1)
        }
    }
}

extension FeatureArt {
    enum Kind: Hashable, Sendable {
        case receipt
        case sync
        case share
        case theme
        case fonts
    }
}

private extension FeatureArt {
    static let width: CGFloat = 330
    static let height: CGFloat = 170
}

private extension FeatureArt {
    @ViewBuilder
    var content: some View {
        switch kind {
        case .receipt: receipt
        case .sync: sync
        case .share: share
        case .theme: theme
        case .fonts: fonts
        }
    }

    var receipt: some View {
        HStack(spacing: 12) {
            FeatureArtReceipt(showsViewfinder: true)
                .rotationEffect(.degrees(-4))
                .padding(12)

            arrow

            VStack(spacing: 8) {
                FeatureArtSlip()

                EntryItemButton(
                    count: FeatureArtSample.items.count,
                    total: FeatureArtSample.total,
                    adjustment: 0
                ) {}
                    .allowsHitTesting(false)
            }
            .frame(width: 156)
        }
    }

    var sync: some View {
        HStack(spacing: 16) {
            phone("いまの iPhone")

            VStack(spacing: 4) {
                Image(systemName: "checkmark.icloud")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Palette.accent)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.hint)

                Text("自動でそろう")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Palette.accentStrong)
            }

            phone("新しい iPhone")
        }
    }

    var share: some View {
        HStack(spacing: 12) {
            member("自分", systemImage: "person.fill")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("家族の財布")
                        .textFont(size: .caption, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)

                    Spacer(minLength: 4)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.accent)
                }

                Text(AmountText.text(32400))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)

                VStack(spacing: 4) {
                    sharedRow("自", title: "スーパー", amount: 2180)
                    sharedRow("家", title: "ドラッグストア", amount: 1340)
                    sharedRow("自", title: "電気代", amount: 6820)
                }
            }
            .padding(12)
            .frame(width: 168)
            .card(cornerRadius: 12)

            member("家族", systemImage: "person.fill")
        }
    }

    var theme: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(Self.themeSamples, id: \.self) { preset in
                VStack(spacing: 4) {
                    ThemePreview(palette: preset.palette)
                        .frame(width: Self.themeWidth)

                    Text(preset.title)
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.subtext)
                }
            }

            VStack(spacing: 4) {
                VStack(spacing: 4) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 20, weight: .light))

                    Text("自分で\n作る")
                        .font(.system(size: 10, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Palette.accent)
                .frame(width: Self.themeWidth, height: 132)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }

                Text("Pro")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.accentStrong)
            }
        }
    }

    var fonts: some View {
        VStack(spacing: 4) {
            ForEach(Self.fontSamples, id: \.self) { sample in
                HStack(alignment: .firstTextBaseline) {
                    Text(sample.title)
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.subtext)
                        .frame(width: 64, alignment: .leading)

                    Text("今月あと \(AmountText.text(FeatureArtSample.remaining))")
                        .font(.display(size: 21, weight: .bold, in: sample.font))
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Palette.card, in: .rect(cornerRadius: 8))
            }
        }
    }

    var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.hint)
    }

    func phone(_ title: String) -> some View {
        VStack(spacing: 4) {
            FeatureArtPhone {
                FeatureArtMiniHome()
            }

            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(Palette.subtext)
        }
    }

    func member(
        _ title: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(Palette.accent)
                .frame(width: 44, height: 44)
                .background(Palette.accent.opacity(.subtle), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Palette.outline, lineWidth: 1)
                }

            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(Palette.subtext)
        }
    }

    func sharedRow(
        _ initial: String,
        title: String,
        amount: Int
    ) -> some View {
        HStack(spacing: 4) {
            Text(initial)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Palette.backgroundTop)
                .frame(width: 14, height: 14)
                .background(Palette.accent, in: Circle())

            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(Palette.text)

            Spacer(minLength: 4)

            Text(AmountText.text(amount))
                .font(.system(size: 9))
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
    }
}

private extension FeatureArt {
    struct FontSample: Hashable {
        let font: ThemeFont
        let title: String
    }

    static let themeSamples: [ThemePreset] = [.sage, .navy]
    static let themeWidth: CGFloat = 92

    static let fontSamples = [
        FontSample(font: .rounded, title: "丸ゴシック"),
        FontSample(font: .handwriting, title: "手書き"),
        FontSample(font: .dot, title: "ドット"),
        FontSample(font: .pop, title: "ポップ")
    ]
}
