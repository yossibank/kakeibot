import DesignSystem
import SwiftUI

struct AssetsDebtChip: View {
    let systemImage: String
    let text: String

    var body: some View {
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
