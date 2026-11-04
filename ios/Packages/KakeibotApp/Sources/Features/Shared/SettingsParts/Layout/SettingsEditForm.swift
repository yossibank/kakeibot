import DesignSystem
import SwiftUI

struct SettingsEditForm<Content: View, Save: View>: View {
    let showsSave: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let save: () -> Save

    var body: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.form) {
                    content()
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            if showsSave {
                save()
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: showsSave)
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
    }
}

private extension SettingsEditForm {
    static var fade: CGFloat {
        16
    }
}
