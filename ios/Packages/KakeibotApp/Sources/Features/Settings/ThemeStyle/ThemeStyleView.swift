import Core
import DesignSystem
import Foundation
import SwiftUI

public struct ThemeStyleView: View {
    @State private var model: ThemeStyleModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            header

            Text("どのテーマでも、画面の角の丸みと字体が変わります")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    preview
                        .environment(\.themeStyle, model.style)

                    choiceRow(
                        "角の丸み",
                        selection: cornerBinding,
                        options: Self.cornerOptions
                    )

                    fontRow(
                        "見出しと金額の字体",
                        selection: displayFontBinding,
                        sample: AmountText.text(Self.sampleAmount)
                    ) { font in
                        .display(.headline, in: font)
                    }

                    fontRow(
                        "本文の字体",
                        selection: textFontBinding,
                        sample: Self.sampleText
                    ) { font in
                        .text(.subheadline, in: font)
                    }
                }
                .padding(.vertical, 8)
            }
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .padding(.horizontal, -18)
            .scrollIndicators(.hidden)
        }
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
        .task {
            await model.load()
        }
    }
}

private extension ThemeStyleView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("角の丸みと字体")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
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

    func choiceRow<Value: Hashable>(
        _ title: String,
        selection: Binding<Value>,
        options: [CapsulePicker<Value>.Option]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            rowTitle(title)

            CapsulePicker(selection: selection, options: options)
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
                    fontTile(
                        choice,
                        isSelected: choice == selection.wrappedValue,
                        sample: sample,
                        font: font(choice)
                    ) {
                        selection.wrappedValue = choice
                    }
                }
            }
        }
    }

    func fontTile(
        _ choice: ThemeFont,
        isSelected: Bool,
        sample: String,
        font: Font,
        action: @escaping () -> Void
    ) -> some View {
        let ring = isSelected ? Palette.accent : Palette.line
        let titleColor = isSelected ? Palette.accentStrong : Palette.subtext
        let ringWidth: CGFloat = isSelected ? 1.5 : 1

        return Button(action: action) {
            VStack(spacing: 6) {
                Text(sample)
                    .font(font)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(choice.title)
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
    static let cornerOptions = ThemeCorner.allCases.map { corner in
        CapsulePicker<ThemeCorner>.Option(corner.title, value: corner)
    }

    static let sampleAmount = 1280
    static let sampleText = "食費・財布"
    static let fontColumns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 3
    )

    var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(14))
    }

    var cornerBinding: Binding<ThemeCorner> {
        Binding {
            model.style.corner
        } set: { corner in
            Task {
                await model.choose(corner)
            }
        }
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
}
