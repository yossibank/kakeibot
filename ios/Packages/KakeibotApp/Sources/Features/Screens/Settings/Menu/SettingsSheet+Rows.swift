import DesignSystem
import SwiftUI

extension SettingsSheet {
    var versionRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text("バージョン")
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)

            Spacer()

            Text(Bundle.main.shortVersion)
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
        .frame(minHeight: 48)
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
    ) -> some View {
        let picker = picker()

        let label = HStack(spacing: 12) {
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

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                label

                Spacer(minLength: 8)

                picker
            }
            .frame(minHeight: 52)

            VStack(alignment: .leading, spacing: 8) {
                label

                picker
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 12)
        }
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil,
        shortValue: String? = nil
    ) -> some View {
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
                .layoutPriority(1)

            Spacer()

            if let value {
                ViewThatFits(in: .horizontal) {
                    Text(value)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize()

                    Text(shortValue ?? value)
                        .lineLimit(1)
                        .minimumScaleFactor(Self.valueScale)
                }
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
            }

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

private extension SettingsSheet {
    static let valueScale: CGFloat = 0.7
}
