import Core
import DesignSystem
import SwiftUI

struct EntryReceiptTaxRateBadge: View {
    let rate: EntryItem.TaxRate

    var body: some View {
        Text("\(rate.rawValue)%")
            .textFont(.caption2, weight: .semibold)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Palette.accentStrong)
            .padding(.horizontal, 4)
            .frame(minWidth: Self.minWidth)
            .padding(.vertical, 1)
            .background(Palette.accent.opacity(.subtle), in: .capsule)
    }
}

private extension EntryReceiptTaxRateBadge {
    static let minWidth: CGFloat = 44
}
