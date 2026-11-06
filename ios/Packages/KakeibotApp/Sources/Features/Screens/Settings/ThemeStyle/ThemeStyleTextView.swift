import Core
import DesignSystem
import SwiftUI

public struct ThemeStyleTextView: View {
    @State private var model: ThemeStyleModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var fontOffer: FontOffer?

    @Environment(\.isPro) private var isPro
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ThemeStyleModel) {
        let hintFlag = model.closedHint(.themeText)

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        ThemeStyleFrame(
            title: "文字",
            intro: Self.intro,
            hint: hintFlag,
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
                label: \.title,
                isLocked: isLocked
            ) { font in
                fontSample(
                    AmountText.text(Self.sampleAmount),
                    font: .display(.headline, in: font, scale: 1),
                    scale: 0.5
                )
            } choose: { font in
                await choose(.display(font))
            }

            ThemeStyleChoices(
                title: "本文の字体",
                options: ThemeFont.allCases,
                selection: model.style.textFont,
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
                await choose(.text(font))
            }
        }
        .proOffer(fontOffer?.feature) {
            fontOffer = nil
            model.cancelPreview()
        } onUnlock: {
            unlock()
        }
    }
}

private extension ThemeStyleTextView {
    enum FontOffer: Equatable {
        case display(ThemeFont)
        case text(ThemeFont)

        var feature: String {
            switch self {
            case let .display(font), let .text(font): "\(font.title)の字体"
            }
        }
    }
}

private extension ThemeStyleTextView {
    var suggestsLarge: Bool {
        dynamicTypeSize >= .xLarge && model.style.textSize != .large
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
            Text("iPhone の文字を大きくしています。このアプリでは「大きめ」にすると読みやすくなります。")
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)

            ChipButton("大きめにする", systemImage: "textformat.size") {
                Task {
                    await model.choose(ThemeTextSize.large)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
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
    static let freeFonts: Set<ThemeFont> = [.mincho, .gothic]

    func isLocked(_ font: ThemeFont) -> Bool {
        !isPro && !Self.freeFonts.contains(font)
    }

    func choose(_ offer: FontOffer) async {
        switch offer {
        case let .display(font) where isLocked(font) && font != model.savedStyle.displayFont:
            model.cancelPreview()
            model.preview(displayFont: font)
            fontOffer = offer

        case let .text(font) where isLocked(font) && font != model.savedStyle.textFont:
            model.cancelPreview()
            model.preview(textFont: font)
            fontOffer = offer

        default:
            fontOffer = nil
            model.cancelPreview()
            await save(offer)
        }
    }

    func unlock() {
        guard let offer = fontOffer else {
            return
        }

        fontOffer = nil

        Task {
            await save(offer)
        }
    }

    func save(_ offer: FontOffer) async {
        switch offer {
        case let .display(font):
            await model.choose(displayFont: font)

        case let .text(font):
            await model.choose(textFont: font)
        }
    }
}

private extension ThemeStyleTextView {
    static let intro = ThemeStyleIntro(
        systemImage: "textformat",
        headline: ("文字の大きさと字体を", "好みに変えられます"),
        notes: [
            .init("eye", "選ぶと、上の見本が変わります"),
            .init("arrow.uturn.backward", "戻ると、アプリ全体が変わります")
        ]
    )

    static let sizeSampleHeight: CGFloat = 30
    static let restCardHeight: CGFloat = 108
    static let sampleRest = 125_560
    static let sampleAmount = 1280
    static let sampleText = "食費・財布"
}
