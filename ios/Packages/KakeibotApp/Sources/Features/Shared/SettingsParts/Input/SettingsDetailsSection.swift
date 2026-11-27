import DesignSystem
import SwiftUI

struct SettingsDetailsSection<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("くわしい設定")

            content()
        }
    }
}
