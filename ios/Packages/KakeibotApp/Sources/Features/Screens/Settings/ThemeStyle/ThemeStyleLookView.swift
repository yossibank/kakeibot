import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ThemeStyleLookView: View {
    @State private var model: ThemeStyleModel

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ThemeStyleFrame(
            title: "形と動き",
            intro: Self.intro,
            hint: hint,
            model: model
        ) {
            preview
        } content: {
            ThemeStyleChoices(
                title: "角の丸み",
                options: ThemeCorner.allCases,
                selection: model.output.style.corner,
                columns: 4,
                label: \.title
            ) { corner in
                cornerMark(corner)
            } choose: { corner in
                model.perform {
                    await $0.choose(corner)
                }
            }

            ThemeStyleChoices(
                title: "行の間隔",
                options: ThemeRowSpacing.allCases,
                selection: model.output.style.rowSpacing,
                columns: 3,
                label: \.title
            ) { spacing in
                spacingMark(spacing)
            } choose: { spacing in
                model.perform {
                    await $0.choose(spacing)
                }
            }

            ThemeStyleChoices(
                title: "スタンプの形",
                options: ThemeStampShape.allCases,
                selection: model.output.style.stampShape,
                columns: 3,
                label: \.title
            ) { shape in
                IconSeal(.styleSample(.star), size: Self.markSize)
                    .environment(\.themeStyle.stampShape, shape)
            } choose: { shape in
                model.perform {
                    await $0.choose(shape)
                }
            }

            ThemeStyleChoices(
                title: "タブの名前",
                options: [true, false],
                selection: model.output.style.showsTabTitles,
                columns: 2,
                label: Self.tabTitle
            ) { showsTitles in
                ThemeStyleTabBar()
                    .environment(\.themeStyle.showsTabTitles, showsTitles)
            } choose: { showsTitles in
                model.perform {
                    await $0.choose(showsTabTitles: showsTitles)
                }
            }

            ThemeStyleChoices(
                title: "背景",
                options: ThemeBackdrop.allCases,
                selection: model.output.style.backdrop,
                columns: 3,
                label: \.title
            ) { backdrop in
                ThemeStyleBackdrop(backdrop: backdrop)
            } choose: { backdrop in
                model.perform {
                    await $0.choose(backdrop)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionTitle("振動と飾り")

                SettingsSwitch(
                    title: "押した時の振動",
                    detail: "選んだ時や記録した時に、軽く振動します",
                    systemImage: "waveform",
                    isOn: model.output.style.haptics
                ) { isOn in
                    model.perform {
                        await $0.choose(haptics: isOn)
                    }
                }

                SettingsSwitch(
                    title: "金の光などの飾り",
                    detail: "ボタンの光とタブの金の輪を出します",
                    systemImage: "sparkle",
                    isOn: model.output.style.decorations
                ) { isOn in
                    model.perform {
                        await $0.choose(decorations: isOn)
                    }
                }
            }
            .environment(\.themeStyle.decorations, model.output.style.decorations)
        }
    }
}

private extension ThemeStyleLookView {
    var preview: some View {
        let shape = RoundedRectangle(cornerRadius: model.output.style.corner.radius(28))

        return VStack(spacing: 8) {
            dayCard

            ThemeStyleTabBar()
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background {
            Backdrop()
        }
        .clipShape(shape)
        .overlay {
            shape
                .strokeBorder(Palette.line, lineWidth: 1)
        }
    }

    var dayCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("10/30")
                        .displayFont(.headline)
                        .foregroundStyle(Palette.accentStrong)

                    Text("（木）")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 8)

                    AmountText(1340, type: .expense, font: .style(.body))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                IconSeal(.styleSample(.star), size: Self.stampSize)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            EntryRow(
                icon: .styleSample(.food),
                title: "ランチ",
                detail: "食費・財布",
                amount: 900,
                type: .expense
            )
            .topHairline()

            EntryRow(
                icon: .styleSample(.transit),
                title: "電車",
                detail: "交通・財布",
                amount: 440,
                type: .expense
            )
            .topHairline()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    func spacingMark(_ spacing: ThemeRowSpacing) -> some View {
        VStack(spacing: spacing.padding) {
            Capsule()
                .fill(Palette.subtext)
                .frame(height: 3)

            Capsule()
                .fill(Palette.subtext)
                .frame(height: 3)

            Capsule()
                .fill(Palette.subtext)
                .frame(height: 3)
        }
        .frame(width: Self.markSize * 1.4, height: Self.markSize)
    }

    func cornerMark(_ option: ThemeCorner) -> some View {
        let color = option == model.output.style.corner ? Palette.accent : Palette.subtext
        return ThemeStyleCornerMark(corner: option, color: color, size: Self.markSize)
    }
}

private extension ThemeStyleLookView {
    static let intro = ThemeStyleIntroContent(
        systemImage: "square.on.circle",
        headline: ("角の丸みや背景などを", "好みに変えられます"),
        notes: [
            .init("eye", "選ぶと、上の見本が変わります"),
            .init("arrow.uturn.backward", "戻ると、アプリ全体が変わります")
        ]
    )

    static let markSize: CGFloat = 30
    static let stampSize: CGFloat = 26

    static func tabTitle(_ showsTitles: Bool) -> String {
        showsTitles ? "出す" : "出さない"
    }
}

private extension ThemeStyleLookView {
    var hint: SettingsFold {
        SettingsFold(\.lookHint, in: model)
    }
}
