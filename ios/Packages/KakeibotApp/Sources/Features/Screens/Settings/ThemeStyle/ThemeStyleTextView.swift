import Core
import DesignSystem
import SwiftUI

public struct ThemeStyleTextView: View {
    @State private var model: ThemeStyleModel

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ThemeStyleScreen(
            title: "文字",
            hint: "文字の大きさと字体を選べます",
            model: model
        ) {
            preview
        } content: {
            ThemeStyleChoices(
                title: "文字の大きさ",
                options: ThemeTextSize.allCases,
                selection: model.style.textSize,
                columns: 3,
                label: \.title
            ) { size in
                Text("あ")
                    .font(.text(.headline, in: model.style.textFont, scale: size.scale))
                    .foregroundStyle(Palette.text)
                    .frame(height: Self.sizeSampleHeight)
            } choose: { size in
                await model.choose(size)
            }

            ThemeStyleChoices(
                title: "見出しと金額の字体",
                options: ThemeFont.allCases,
                selection: model.style.displayFont,
                columns: 3,
                label: \.title
            ) { font in
                fontSample(
                    AmountText.text(Self.sampleAmount),
                    font: .display(.headline, in: font, scale: 1),
                    scale: 0.5
                )
            } choose: { font in
                await model.choose(displayFont: font)
            }

            ThemeStyleChoices(
                title: "本文の字体",
                options: ThemeFont.allCases,
                selection: model.style.textFont,
                columns: 3,
                label: \.title
            ) { font in
                fontSample(
                    Self.sampleText,
                    font: .text(.subheadline, in: font, scale: 1),
                    scale: 0.8
                )
            } choose: { font in
                await model.choose(textFont: font)
            }
        }
    }
}

private extension ThemeStyleTextView {
    var preview: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("今月あといくら")
                    .textFont(size: .caption)
                    .tracking(4)
                    .foregroundStyle(Palette.accent)
                    .minimumScaleFactor(0.8)

                Text(AmountText.text(Self.sampleRest))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .minimumScaleFactor(0.5)

                Text("予算 ¥200,000")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.subtext)
                    .minimumScaleFactor(0.8)
            }
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: Self.restCardHeight)
            .card()

            HStack(spacing: 12) {
                TemplateCard(
                    icon: .styleSample(.food),
                    name: "ランチ",
                    detail: "食費・財布",
                    amount: 900
                )

                TemplateCard(
                    icon: .styleSample(.transit),
                    name: "電車",
                    detail: "交通・財布",
                    amount: 440
                )
            }
        }
    }

    func fontSample(
        _ text: String,
        font: Font,
        scale: CGFloat
    ) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(Palette.text)
            .lineLimit(1)
            .minimumScaleFactor(scale)
    }
}

private extension ThemeStyleTextView {
    static let sizeSampleHeight: CGFloat = 30
    static let restCardHeight: CGFloat = 108
    static let sampleRest = 125_560
    static let sampleAmount = 1280
    static let sampleText = "食費・財布"
}
