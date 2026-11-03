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
    ) -> SettingsPickerRow<some View> {
        SettingsPickerRow(title, systemImage: systemImage, picker: picker())
    }

    func switchRow(
        _ title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> SettingsSwitchRow {
        SettingsSwitchRow(title, systemImage: systemImage, isOn: isOn)
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil,
        shortValue: String? = nil,
        tint: Color? = nil,
        trailingImage: String = "chevron.right"
    ) -> SettingsRow<SettingsRowValue?> {
        let accessory = value.map { SettingsRowValue(value: $0, shortValue: shortValue) }

        return SettingsRow(
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
    ) -> SettingsRow<some View> {
        SettingsRow(
            title,
            systemImage: systemImage,
            tint: tint,
            trailingImage: trailingImage,
            accessory: accessory()
        )
    }
}

struct SettingsRow<Accessory: View>: View {
    let title: String
    let systemImage: String
    let tint: Color?
    let trailingImage: String
    let accessory: Accessory

    init(
        _ title: String,
        systemImage: String,
        tint: Color?,
        trailingImage: String,
        accessory: Accessory
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.trailingImage = trailingImage
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(tint ?? Palette.accent)
                .frame(width: 22)

            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(tint ?? Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)

            Spacer()

            accessory

            Image(systemName: trailingImage)
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

struct SettingsSwitchRow: View {
    let title: String
    let systemImage: String
    let isOn: Binding<Bool>

    init(
        _ title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isOn = isOn
    }

    var body: some View {
        GoldSwitch(
            isOn: isOn,
            systemImage: systemImage,
            insets: EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        ) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22)

                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct SettingsPickerRow<Picker: View>: View {
    let title: String
    let systemImage: String
    let picker: Picker

    init(
        _ title: String,
        systemImage: String,
        picker: Picker
    ) {
        self.title = title
        self.systemImage = systemImage
        self.picker = picker
    }

    var body: some View {
        PickerRowLayout {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22)

                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }

            picker
        }
    }
}

struct SettingsRowValue: View {
    let value: String
    let shortValue: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(value)
                .textFont(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize()

            if let shortValue {
                Text(shortValue)
                    .textFont(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }

            Text(shortValue ?? value)
                .textFont(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize()

            Color.clear
                .frame(width: 0, height: 0)
        }
        .foregroundStyle(Palette.subtext)
    }
}

private struct PickerRowLayout: Layout {
    static let gap: CGFloat = 20
    static let rowHeight: CGFloat = 52
    static let lineSpacing: CGFloat = 8
    static let inset: CGFloat = 12

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let label = subviews[0].sizeThatFits(.unspecified)
        let picker = subviews[1].sizeThatFits(.unspecified)
        let rowWidth = label.width + Self.gap + picker.width
        let width = proposal.width ?? rowWidth

        guard rowWidth > width else {
            return CGSize(width: width, height: max(label.height, picker.height, Self.rowHeight))
        }

        let height = label.height + Self.lineSpacing + picker.height + Self.inset * 2

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let label = subviews[0].sizeThatFits(.unspecified)
        let picker = subviews[1].sizeThatFits(.unspecified)
        let rowWidth = label.width + Self.gap + picker.width

        guard rowWidth > bounds.width else {
            let leading = CGPoint(x: bounds.minX, y: bounds.midY)
            let trailing = CGPoint(x: bounds.maxX, y: bounds.midY)

            subviews[0].place(at: leading, anchor: .leading, proposal: .unspecified)
            subviews[1].place(at: trailing, anchor: .trailing, proposal: .unspecified)

            return
        }

        let top = CGPoint(x: bounds.minX, y: bounds.minY + Self.inset)
        let bottom = CGPoint(x: bounds.maxX, y: bounds.maxY - Self.inset)

        subviews[0].place(at: top, anchor: .topLeading, proposal: .unspecified)
        subviews[1].place(at: bottom, anchor: .bottomTrailing, proposal: .unspecified)
    }
}
