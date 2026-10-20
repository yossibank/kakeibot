import Core
import DesignSystem
import Foundation
import SwiftUI

public struct ThemeStyleView: View {
    @State private var model: ThemeStyleModel

    @Environment(\.dismiss) private var dismiss

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            header

            Text("どのテーマでも、画面の角の丸みと、見出しと金額の字体が変わります")
                .font(.caption)
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

                    choiceRow(
                        "字体",
                        selection: fontBinding,
                        options: Self.fontOptions
                    )
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
                    .font(.sans(.caption))
                    .tracking(4)
                    .foregroundStyle(Palette.accent)

                Text(AmountText.text(Self.sampleRest))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
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
            Text(title)
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 6)

            CapsulePicker(selection: selection, options: options)
        }
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

    static let fontOptions = ThemeFont.allCases.map { font in
        CapsulePicker<ThemeFont>.Option(font.title, value: font)
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

    var fontBinding: Binding<ThemeFont> {
        Binding {
            model.style.font
        } set: { font in
            Task {
                await model.choose(font)
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
