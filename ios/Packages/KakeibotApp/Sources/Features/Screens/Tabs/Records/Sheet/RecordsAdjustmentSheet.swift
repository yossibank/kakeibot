import Core
import DesignSystem
import SwiftUI

struct RecordsAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let row: RecordsModel.AdjustmentRow
    let onDelete: () -> Void

    var body: some View {
        FittedSheet {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: RecordsAdjustmentRow.systemImage)
                        .sansFont(.title, weight: .light)
                        .foregroundStyle(Palette.accent)

                    SheetTitle(RecordsAdjustmentRow.title)

                    Text(row.amountText)
                        .displayFont(.largeTitle, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(detail)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text("口座の残高だけを動かす記録です。\n支出や収入、予算には入りません。")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                ChipButton(
                    "削除して前の残高に戻す",
                    systemImage: "trash",
                    size: .large
                ) {
                    onDelete()
                    dismiss()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension RecordsAdjustmentSheet {
    var detail: String {
        let date = row.adjustment.date
        return "\(row.walletName) · \(date.month)/\(date.day)（\(date.weekday.shortName)）"
    }
}
