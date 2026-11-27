import DesignSystem
import SwiftUI

struct SettingsMenuRow<Accessory: View>: View {
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

struct SettingsMenuRowText: View {
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
