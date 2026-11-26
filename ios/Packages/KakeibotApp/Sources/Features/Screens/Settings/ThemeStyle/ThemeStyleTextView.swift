import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ThemeStyleTextView: View {
    @State private var model: ThemeStyleModel

    @Environment(\.isPro) private var isPro
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ThemeStyleFrame(
            title: "文字",
            intro: Self.intro,
            hint: hint,
            model: model
        ) {
            preview
        } content: {
            if suggestsLarge {
                largeSuggestion
            }

            ThemeStyleChoices(
                title: "文字の大きさ",
                options: ThemeTextSize.allCases,
                selection: model.output.style.textSize,
                columns: 3,
                label: \.title
            ) { size in
                Text("あ")
                    .font(.text(.headline, in: model.output.style.textFont, scale: size.scale))
                    .foregroundStyle(Palette.text)
                    .frame(height: Self.sizeSampleHeight)
            } choose: { size in
                model.perform {
                    await $0.choose(size)
                }
            }

            displayFontChoices

            textFontChoices
        }
        .proOffer(model.state.fontOffer?.feature) {
            model.closeFontOffer()
        } onUnlock: {
            model.perform {
                await $0.unlockFont()
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

                AmountText(
                    Self.sampleRest,
                    font: .size(.title, weight: .bold),
                    color: Palette.accentStrong
                )
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

    var largeSuggestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(DeviceName.current) の文字を大きくしています。このアプリでは「大きめ」にすると読みやすくなります。")
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            ChipButton("大きめにする", systemImage: "textformat.size") {
                model.perform {
                    await $0.choose(ThemeTextSize.large)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var displayFontChoices: some View {
        ThemeStyleChoices(
            title: "見出しと金額の字体",
            options: ThemeFont.allCases,
            selection: model.output.style.displayFont,
            columns: 3,
            label: \.title,
            isLocked: isLocked
        ) { font in
            fontSample(
                Yen.text(Self.sampleAmount),
                font: .display(.headline, in: font, scale: 1),
                scale: 0.5
            )
        } choose: { font in
            choose(.display(font))
        }
    }

    var textFontChoices: some View {
        ThemeStyleChoices(
            title: "本文の字体",
            options: ThemeFont.allCases,
            selection: model.output.style.textFont,
            columns: 3,
            label: \.title,
            isLocked: isLocked
        ) { font in
            fontSample(
                Self.sampleText,
                font: .text(.subheadline, in: font, scale: 1),
                scale: 0.8
            )
        } choose: { font in
            choose(.text(font))
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

    static let intro = ThemeStyleIntroContent(
        systemImage: "textformat",
        headline: ("文字の大きさと字体を", "好みに変えられます"),
        notes: [
            .init("eye", "選ぶと、上の見本が変わります"),
            .init("arrow.uturn.backward", "戻ると、アプリ全体が変わります")
        ]
    )

    var suggestsLarge: Bool {
        dynamicTypeSize >= .xLarge && model.output.style.textSize != .large
    }

    var hint: SettingsFold {
        SettingsFold(\.textHint, in: model)
    }

    func isLocked(_ font: ThemeFont) -> Bool {
        ThemeStyleModel.isLocked(font, isPro: isPro)
    }

    func choose(_ offer: ThemeStyleModel.FontOffer) {
        model.perform { [isPro] in
            await $0.choose(offer, isPro: isPro)
        }
    }
}
