import Core
import DesignSystem
import SwiftUI

public struct ThemeStyleLookView: View {
    @State private var model: ThemeStyleModel

    public init(model: ThemeStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ThemeStyleScreen(
            title: "見た目と動き",
            hint: "角の丸みや行の間隔、スタンプの形、背景を選べます",
            model: model
        ) {
            preview
        } content: {
            ThemeStyleChoices(
                title: "角の丸み",
                options: ThemeCorner.allCases,
                selection: model.style.corner,
                columns: 4,
                label: \.title
            ) { corner in
                cornerMark(corner)
            } choose: { corner in
                await model.choose(corner)
            }

            ThemeStyleChoices(
                title: "行の間隔",
                options: ThemeRowSpacing.allCases,
                selection: model.style.rowSpacing,
                columns: 3,
                label: \.title
            ) { spacing in
                spacingMark(spacing)
            } choose: { spacing in
                await model.choose(spacing)
            }

            ThemeStyleChoices(
                title: "スタンプの形",
                options: ThemeStampShape.allCases,
                selection: model.style.stampShape,
                columns: 3,
                label: \.title
            ) { shape in
                IconSeal(.styleSample(.star), size: Self.markSize)
                    .environment(\.themeStyle.stampShape, shape)
            } choose: { shape in
                await model.choose(shape)
            }

            ThemeStyleChoices(
                title: "タブの名前",
                options: [true, false],
                selection: model.style.showsTabTitles,
                columns: 2,
                label: Self.tabTitle
            ) { showsTitles in
                tabMark(showsTitles)
                    .frame(height: Self.markSize)
            } choose: { showsTitles in
                await model.choose(showsTabTitles: showsTitles)
            }

            ThemeStyleChoices(
                title: "背景",
                options: ThemeBackdrop.allCases,
                selection: model.style.backdrop,
                columns: 3,
                label: \.title
            ) { backdrop in
                Backdrop()
                    .frame(width: Self.markSize * 2.4, height: Self.markSize * 1.4)
                    .clipShape(.rect(cornerRadius: 4))
                    .environment(\.themeStyle.backdrop, backdrop)
            } choose: { backdrop in
                await model.choose(backdrop)
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionTitle("振動と飾り")

                ThemeStyleSwitch(
                    title: "押した時の振動",
                    detail: "選んだ時や記録した時に、軽く振動します",
                    isOn: model.style.haptics
                ) { isOn in
                    await model.choose(haptics: isOn)
                }

                ThemeStyleSwitch(
                    title: "金の光などの飾り",
                    detail: "ボタンの光とタブの金の輪を出します",
                    isOn: model.style.decorations
                ) { isOn in
                    await model.choose(decorations: isOn)
                }
            }
        }
    }
}

private extension ThemeStyleLookView {
    var preview: some View {
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

                    AmountText(1340, type: .expense)
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
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }

            EntryRow(
                icon: .styleSample(.transit),
                title: "電車",
                detail: "交通・財布",
                amount: 440,
                type: .expense
            )
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }
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

    func tabMark(_ showsTitles: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "house")
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)

            if showsTitles {
                Text("ホーム")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.accentStrong)
            }
        }
    }

    func cornerMark(_ option: ThemeCorner) -> some View {
        let isSelected = option == model.style.corner
        let color = isSelected ? Palette.accent : Palette.subtext
        let size = Self.markSize
        let radius = option.radius(Self.cornerMarkRadius)

        return RoundedRectangle(cornerRadius: radius)
            .stroke(color, lineWidth: 2.5)
            .frame(width: size * 2, height: size * 2)
            .frame(width: size, height: size, alignment: .topLeading)
            .offset(x: size * 0.15, y: size * 0.15)
            .frame(width: size, height: size)
            .clipped()
    }
}

private extension ThemeStyleLookView {
    static let markSize: CGFloat = 30
    static let stampSize: CGFloat = 26
    static let cornerMarkRadius: CGFloat = 20

    static func tabTitle(_ showsTitles: Bool) -> String {
        showsTitles ? "出す" : "出さない"
    }
}
