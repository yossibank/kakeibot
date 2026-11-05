import Core
import DesignSystem
import SwiftUI

struct SettingsFormSection<Content: View>: View {
    let title: String
    let value: String?
    let valueIcon: Icon?
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        value: String? = nil,
        valueIcon: Icon? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.value = value
        self.valueIcon = valueIcon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SettingsSectionTitle(title)
                    .layoutPriority(1)

                Spacer(minLength: 8)

                if let value {
                    HStack(spacing: 4) {
                        if let valueIcon {
                            IconImage(valueIcon, size: 11)
                        }

                        Text(value)
                            .textFont(.footnote)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(Palette.accentStrong)
                    .padding(.trailing, 8)
                }
            }

            content()
        }
    }
}
