import Core
import DesignSystem
import SwiftUI

extension FeatureArt {
    var receipt: some View {
        HStack(spacing: 10) {
            EntryReceiptButton(freeLeft: nil) {}
                .allowsHitTesting(false)

            Image(systemName: "arrow.right")
                .textFont(.caption, weight: .semibold)
                .foregroundStyle(Palette.hint)

            slip(Self.sampleItems.prefix(3), showsRates: false)
        }
    }

    var items: some View {
        slip(Self.sampleItems.prefix(3), showsRates: true)
            .frame(maxWidth: 220)
    }

    var carryover: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.62)

                Text(AmountText.text(42180))
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }
            .frame(width: 140, height: 70)

            Text("先月から \(AmountText.text(3200))")
                .textFont(.caption2, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Palette.accent.opacity(.subtle), in: .capsule)
        }
    }

    var sync: some View {
        HStack(spacing: 10) {
            phone

            VStack(spacing: 4) {
                Image(systemName: "icloud")
                    .sansFont(.body, weight: .light)

                Image(systemName: "arrow.left.arrow.right")
                    .textFont(.caption2)
            }
            .foregroundStyle(Palette.accent)

            phone
        }
    }

    var share: some View {
        HStack(spacing: 10) {
            person("person.fill")

            VStack(alignment: .leading, spacing: 4) {
                Text("家族の財布")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(12400))
                    .displayFont(.body, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .card(cornerRadius: 12)

            person("person.fill")
        }
    }

    var theme: some View {
        HStack(spacing: -8) {
            ForEach(Self.themeSamples, id: \.self) { preset in
                swatch(preset.palette)
            }
        }
    }

    var fonts: some View {
        HStack(spacing: 14) {
            ForEach(Self.fontSamples, id: \.self) { sample in
                VStack(spacing: 4) {
                    Text("あ")
                        .font(.display(size: 30, in: sample.font))
                        .foregroundStyle(Palette.accentStrong)

                    Text(sample.title)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
    }
}

private extension FeatureArt {
    struct FontSample: Hashable {
        let font: ThemeFont
        let title: String
    }

    struct SampleItem: Hashable {
        let name: String
        let amount: Int
        let rate: EntryItem.TaxRate
    }

    static let sampleItems = [
        SampleItem(name: "牛乳", amount: 198, rate: .reduced),
        SampleItem(name: "食パン", amount: 168, rate: .reduced),
        SampleItem(name: "洗剤", amount: 398, rate: .standard)
    ]

    static let themeSamples: [ThemePreset] = [.ivory, .sky, .sage, .navy, .wine]

    static let fontSamples = [
        FontSample(font: .rounded, title: "丸ゴシック"),
        FontSample(font: .handwriting, title: "手書き"),
        FontSample(font: .dot, title: "ドット"),
        FontSample(font: .pop, title: "ポップ")
    ]

    static let tooth: CGFloat = 6

    static func color(_ rgb: UInt32) -> Color {
        Color(hex: String(format: "%06X", rgb)) ?? Palette.accent
    }
}

private extension FeatureArt {
    var phone: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == 0 ? Palette.accent : Palette.line)
                    .frame(height: 3)
            }
        }
        .padding(8)
        .frame(width: 44, height: 76, alignment: .top)
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(Palette.outline, lineWidth: 1.2)
        }
    }

    func swatch(_ palette: ThemePalette) -> some View {
        let background = Self.color(palette.backgroundTop)
        let accent = Self.color(palette.accent)

        return Circle()
            .fill(background)
            .overlay {
                Circle()
                    .fill(accent)
                    .padding(10)
            }
            .overlay {
                Circle()
                    .stroke(Palette.outline, lineWidth: 1)
            }
            .frame(width: 40, height: 40)
    }

    func person(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .sansFont(.body, weight: .light)
            .foregroundStyle(Palette.accent)
            .frame(width: 36, height: 36)
            .background(Palette.accent.opacity(.subtle), in: Circle())
    }

    func slip(
        _ items: ArraySlice<SampleItem>,
        showsRates: Bool
    ) -> some View {
        VStack(spacing: 5) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.name)
                        .foregroundStyle(Palette.text)
                        .fixedSize()

                    if showsRates {
                        EntryTaxRateBadge(rate: item.rate)
                    }

                    EntryReceiptLeader()

                    Text(AmountText.text(item.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                        .fixedSize()
                }
            }
        }
        .textFont(.caption2)
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 8 + Self.tooth / 2)
        .background {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .fill(Palette.paper)
                .shadow(color: Palette.shadow.opacity(0.4), radius: 3, y: 1)
        }
        .overlay {
            EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
                .stroke(Palette.paperEdge, lineWidth: 1)
        }
    }
}
