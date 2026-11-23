import DesignSystem
import SwiftUI

struct AssetsDebtChip: View {
    var shortText: String?

    let systemImage: String
    let text: String

    init(
        systemImage: String,
        text: String,
        shortText: String? = nil
    ) {
        self.systemImage = systemImage
        self.text = text
        self.shortText = shortText
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chip(text)

            if let shortText {
                chip(shortText)
            }
        }
    }
}

private extension AssetsDebtChip {
    func chip(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .sansFont(.small)
                .foregroundStyle(Palette.accent)

            Text(text)
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Palette.accent.opacity(.faint), in: .capsule)
    }
}
