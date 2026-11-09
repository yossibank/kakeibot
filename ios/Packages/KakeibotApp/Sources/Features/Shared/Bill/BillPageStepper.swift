import Core
import DesignSystem
import SwiftUI

struct BillPageStepper: View {
    let month: YearMonth
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let onMove: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            arrow(systemImage: "chevron.left", count: -1, isEnabled: canMoveBackward)

            Text(BillText.page(month))
                .textFont(.subheadline, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText())

            arrow(systemImage: "chevron.right", count: 1, isEnabled: canMoveForward)
        }
    }
}

private extension BillPageStepper {
    func arrow(
        systemImage: String,
        count: Int,
        isEnabled: Bool
    ) -> some View {
        Button {
            onMove(count)
        } label: {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(isEnabled ? Palette.subtext : Palette.line)
                .frame(width: 32, height: 32)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
