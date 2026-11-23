import Core
import DesignSystem
import SwiftUI

extension SettingsMenuSheet {
    var versionText: some View {
        Text("かけいぼっと \(Bundle.main.shortVersion)")
            .textFont(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.hint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
    }

    func section(
        _ title: String,
        @ViewBuilder rows: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)

            VStack(spacing: 0) {
                rows()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .card()
        }
    }

    func sectionTitle(_ title: String) -> some View {
        SectionTitle(title)
            .padding(.leading, 8)
    }

    func pickerRow(
        _ title: String,
        systemImage: String,
        @ViewBuilder picker: () -> some View
    ) -> SettingsMenuPickerRow<some View> {
        SettingsMenuPickerRow(title, systemImage: systemImage, picker: picker())
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil,
        shortValue: String? = nil,
        tint: Color? = nil,
        trailingImage: String = "chevron.right"
    ) -> SettingsMenuRow<SettingsMenuRowValue?> {
        let accessory = value.map { SettingsMenuRowValue(value: $0, shortValue: shortValue) }

        return SettingsMenuRow(
            title,
            systemImage: systemImage,
            tint: tint,
            trailingImage: trailingImage,
            accessory: accessory
        )
    }

    func row(
        _ title: String,
        systemImage: String,
        tint: Color? = nil,
        trailingImage: String = "chevron.right",
        @ViewBuilder accessory: () -> some View
    ) -> SettingsMenuRow<some View> {
        SettingsMenuRow(
            title,
            systemImage: systemImage,
            tint: tint,
            trailingImage: trailingImage,
            accessory: accessory()
        )
    }
}
