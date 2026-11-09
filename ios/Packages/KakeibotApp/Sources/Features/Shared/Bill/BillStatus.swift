import Core
import DesignSystem
import SwiftUI

struct BillStatus: View {
    let bill: CardBill
    let today: LocalDate

    var body: some View {
        HStack(spacing: 4) {
            if bill.isOpen {
                BillRing(progress: bill.progress(on: today))

                ViewThatFits(in: .horizontal) {
                    Text(BillText.estimate(of: bill))
                    Text(BillText.estimate)
                }
                .foregroundStyle(Palette.accent)
            } else {
                Image(systemName: "checkmark")
                    .sansFont(.micro, weight: .heavy)
                    .foregroundStyle(Palette.backgroundBottom)
                    .frame(width: 14, height: 14)
                    .background(Palette.accent, in: .circle)

                Text(BillText.settled)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .textFont(.caption2, weight: .semibold)
        .monospacedDigit()
        .lineLimit(1)
    }
}
