import DesignSystem
import SwiftUI

struct SettingsFormSection<Content: View>: View {
    let title: String
    let value: String?
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        value: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.value = value
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SettingsSectionTitle(title)

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .textFont(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 8)
                }
            }

            content()
        }
    }
}
