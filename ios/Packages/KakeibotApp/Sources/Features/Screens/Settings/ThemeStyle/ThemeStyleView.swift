import Core
import DesignSystem
import Foundation
import SwiftUI

public struct ThemeStyleView: View {
    @State private var model: ThemeStyleModel
    @State private var openedStyle: ThemeStyle?

    @Environment(\.themeStyle) private var appStyle
    @Environment(\.themeStyle.corner) private var corner

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("文字と角の丸み")

            preview
                .environment(\.themeStyle, model.style)
                .font(model.style.bodyFont)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("文字の大きさと字体、画面の角の丸みを選べます")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .frame(maxWidth: .infinity)

                    textSizeRow

                    fontRow(
                        "見出しと金額の字体",
                        selection: displayFontBinding,
                        sample: AmountText.text(Self.sampleAmount)
                    ) { font in
                        .display(.headline, in: font, scale: 1)
                    }

                    fontRow(
                        "本文の字体",
                        selection: textFontBinding,
                        sample: Self.sampleText
                    ) { font in
                        .text(.subheadline, in: font, scale: 1)
                    }

                    cornerRow
                }
            }
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .contentMargins(.vertical, Self.fade, for: .scrollContent)
            .edgeFade(Self.fade)
            .padding(.horizontal, -18)
            .scrollIndicators(.hidden)
        }
        .environment(\.themeStyle, shownStyle)
        .font(shownStyle.bodyFont)
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.style)
        .onAppear {
            openedStyle = openedStyle ?? appStyle
        }
        .task {
            await model.load()
        }
    }
}

private extension ThemeStyleView {
    var preview: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("今月あといくら")
                    .textFont(size: .caption)
                    .tracking(4)
                    .foregroundStyle(Palette.accent)

                Text(AmountText.text(Self.sampleRest))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                Text("予算 ¥200,000　1 日あたり ¥10,463")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.subtext)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: Self.restCardHeight)
            .card()

            HStack(spacing: 12) {
                ForEach(Self.samples, id: \.name) { sample in
                    TemplateCard(
                        icon: sample.icon,
                        name: sample.name,
                        detail: sample.detail,
                        amount: sample.amount
                    )
                }
            }
        }
        .animation(.snappy(duration: 0.25), value: model.style)
    }

    var cornerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowTitle("角の丸み")

            HStack(spacing: 10) {
                ForEach(ThemeCorner.allCases, id: \.self) { option in
                    tile(
                        option.title,
                        isSelected: option == model.style.corner
                    ) {
                        Task {
                            await model.choose(option)
                        }
                    } content: {
                        cornerMark(option)
                    }
                }
            }
        }
    }

    var textSizeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowTitle("文字の大きさ")

            HStack(spacing: 10) {
                ForEach(ThemeTextSize.allCases, id: \.self) { option in
                    tile(
                        option.title,
                        isSelected: option == model.style.textSize
                    ) {
                        Task {
                            await model.choose(option)
                        }
                    } content: {
                        Text("あ")
                            .font(sizeSampleFont(option))
                            .foregroundStyle(Palette.text)
                            .frame(height: Self.sizeSampleHeight)
                    }
                }
            }
        }
    }

    func fontRow(
        _ title: String,
        selection: Binding<ThemeFont>,
        sample: String,
        font: @escaping (ThemeFont) -> Font
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            rowTitle(title)

            LazyVGrid(columns: Self.fontColumns, spacing: 10) {
                ForEach(ThemeFont.allCases, id: \.self) { choice in
                    tile(
                        choice.title,
                        isSelected: choice == selection.wrappedValue
                    ) {
                        selection.wrappedValue = choice
                    } content: {
                        Text(sample)
                            .font(font(choice))
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
    }

    func cornerMark(_ option: ThemeCorner) -> some View {
        let isSelected = option == model.style.corner
        let color = isSelected ? Palette.accent : Palette.subtext
        let size = Self.cornerMarkSize
        let radius = option.radius(Self.cornerMarkRadius)

        return RoundedRectangle(cornerRadius: radius)
            .stroke(color, lineWidth: 2.5)
            .frame(width: size * 2, height: size * 2)
            .frame(width: size, height: size, alignment: .topLeading)
            .offset(x: size * 0.15, y: size * 0.15)
            .frame(width: size, height: size)
            .clipped()
    }

    func tile(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        let ring = isSelected ? Palette.accent : Palette.line
        let titleColor = isSelected ? Palette.accentStrong : Palette.subtext
        let ringWidth: CGFloat = isSelected ? 1.5 : 1

        return Button(action: action) {
            VStack(spacing: 6) {
                content()

                Text(title)
                    .textFont(.caption2)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 6)
            .background(Palette.panel, in: tileShape)
            .overlay {
                tileShape
                    .stroke(ring, lineWidth: ringWidth)
            }
            .contentShape(tileShape)
        }
        .buttonStyle(.plain)
    }

    func rowTitle(_ title: String) -> some View {
        Text(title)
            .textFont(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.accent)
            .padding(.leading, 6)
    }
}

private extension ThemeStyleView {
    struct Sample {
        let icon: Icon
        let name: String
        let detail: String
        let amount: Int
    }

    static let sampleRest = 125_560
    static let samples = [
        Sample(
            icon: sampleIcon(.food),
            name: "ランチ",
            detail: "食費・財布",
            amount: 900
        ),
        Sample(
            icon: sampleIcon(.transit),
            name: "電車",
            detail: "交通・財布",
            amount: 440
        )
    ]
    static let fade: CGFloat = 16
    static let restCardHeight: CGFloat = 108
    static let cornerMarkSize: CGFloat = 30
    static let cornerMarkRadius: CGFloat = 18
    static let sizeSampleHeight: CGFloat = 30
    static let sampleAmount = 1280
    static let sampleText = "食費・財布"
    static let fontColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 3
    )

    var shownStyle: ThemeStyle {
        openedStyle ?? appStyle
    }

    var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(14))
    }

    var displayFontBinding: Binding<ThemeFont> {
        Binding {
            model.style.displayFont
        } set: { font in
            Task {
                await model.choose(displayFont: font)
            }
        }
    }

    var textFontBinding: Binding<ThemeFont> {
        Binding {
            model.style.textFont
        } set: { font in
            Task {
                await model.choose(textFont: font)
            }
        }
    }

    static func sampleIcon(_ glyph: Icon.Glyph) -> Icon {
        Icon(
            emoji: nil,
            text: nil,
            glyph: glyph,
            color: "#E8735A",
            createdAt: .distantPast,
            updatedAt: .distantPast
        )
    }

    func sizeSampleFont(_ size: ThemeTextSize) -> Font {
        .text(.headline, in: model.style.textFont, scale: size.scale)
    }
}
