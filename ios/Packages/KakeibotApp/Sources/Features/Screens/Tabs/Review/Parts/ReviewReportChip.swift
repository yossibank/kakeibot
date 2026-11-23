import DesignSystem
import SwiftUI

struct ReviewReportChip: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .sansFont(.micro, weight: .bold)

            Text(title)
                .textFont(.caption2, weight: .bold)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Palette.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Palette.accent.opacity(.subtle),
            in: .rect(cornerRadius: ReviewReportRadius.block)
        )
    }
}
