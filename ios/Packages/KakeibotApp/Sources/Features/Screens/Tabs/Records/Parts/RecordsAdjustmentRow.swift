import Core
import DesignSystem
import SwiftUI

struct RecordsAdjustmentRow: View {
    @Environment(\.themeStyle.rowSpacing) private var rowSpacing

    let row: RecordsModel.AdjustmentRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: Self.systemImage)
                .sansFont(.small, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 21, height: 21)

            VStack(alignment: .leading, spacing: 4) {
                Text(Self.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(row.walletName)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, rowSpacing.padding)

            Spacer(minLength: 8)

            AmountText(
                row.adjustment.amount,
                font: .size(.body),
                sign: .plus,
                color: Palette.subtext
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .layoutPriority(2)
        }
        .frame(minHeight: rowSpacing.minHeight)
        .contentShape(.rect)
    }
}

extension RecordsAdjustmentRow {
    static let title = "残高の調整"
    static let systemImage = "scalemass"
}
