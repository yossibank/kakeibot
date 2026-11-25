import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct ThemeStyleFrame<Preview: View, Content: View>: View {
    @Environment(\.themeStyle) private var appStyle

    let title: String
    let intro: ThemeStyleIntroContent
    let hint: SettingsFold
    let model: ThemeStyleModel

    @ViewBuilder let preview: Preview
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader(title, hint: hint)

            preview
                .animation(.snappy(duration: 0.25), value: model.output.style)
                .environment(\.themeStyle, model.output.style)
                .font(model.output.style.bodyFont)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    SettingsIntroCard(
                        systemImage: intro.systemImage,
                        headline: intro.headline,
                        notes: intro.notes,
                        hint: hint
                    )

                    content
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.vertical, Self.fade, for: .scrollContent)
            .edgeFade(Self.fade)
            .padding(.horizontal, -20)
            .scrollIndicators(.hidden)
        }
        .environment(\.themeStyle, shownStyle)
        .font(shownStyle.bodyFont)
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.state.errorNotice) {
            model.state.errorNotice.clear()
        }
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.selection, trigger: model.output.style, condition: Self.isSwitchKept)
        .environment(\.themeStyle.haptics, model.output.style.haptics)
        .onAppear {
            model.open(with: appStyle)
        }
        .task {
            await model.load()
        }
    }
}

private extension ThemeStyleFrame {
    static var fade: CGFloat {
        16
    }

    var shownStyle: ThemeStyle {
        model.input.openedStyle ?? appStyle
    }

    static func isSwitchKept(
        _ old: ThemeStyle,
        _ new: ThemeStyle
    ) -> Bool {
        old.haptics == new.haptics && old.decorations == new.decorations
    }
}

extension Icon {
    static func styleSample(_ glyph: Glyph) -> Icon {
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
