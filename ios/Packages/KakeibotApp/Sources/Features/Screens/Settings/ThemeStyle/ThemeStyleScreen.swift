import Core
import DesignSystem
import SwiftUI

struct ThemeStyleScreen<Preview: View, Content: View>: View {
    @State private var openedStyle: ThemeStyle?

    @Environment(\.themeStyle) private var appStyle

    let title: String
    let hint: String
    let model: ThemeStyleModel
    @ViewBuilder let preview: Preview
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader(title)

            preview
                .animation(.snappy(duration: 0.25), value: model.style)
                .environment(\.themeStyle, model.style)
                .font(model.style.bodyFont)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(hint)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .frame(maxWidth: .infinity)

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
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.selection, trigger: model.style)
        .onAppear {
            openedStyle = openedStyle ?? appStyle
        }
        .task {
            await model.load()
        }
    }
}

private extension ThemeStyleScreen {
    static var fade: CGFloat {
        16
    }

    var shownStyle: ThemeStyle {
        openedStyle ?? appStyle
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
