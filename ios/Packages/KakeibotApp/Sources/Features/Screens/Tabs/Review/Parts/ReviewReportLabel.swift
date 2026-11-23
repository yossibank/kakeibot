import DesignSystem
import SwiftUI

struct ReviewReportLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .textFont(.caption2, weight: .bold)
                .tracking(2)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(Self.line)
                .frame(height: 1)
        }
    }
}

private extension ReviewReportLabel {
    static var line: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.muted), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
