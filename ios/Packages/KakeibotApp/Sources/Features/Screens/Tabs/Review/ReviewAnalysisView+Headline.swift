import Core
import DesignSystem
import SwiftUI

extension ReviewBreakdown.Focus {
    var rising: Self? {
        hasPrevious && amount > previousAmount
            ? self
            : nil
    }
}

extension ReviewAnalysisView {
    func headline(_ focus: ReviewBreakdown.Focus) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.signed(focus.amount - focus.previousAmount))
                .displayFont(.display, weight: .bold)
                .foregroundStyle(Palette.increase)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .monospacedDigit()

            Text("\(focus.name)・前の\(unit)より")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    func reasonChips(_ focus: ReviewBreakdown.Focus) -> some View {
        HStack(spacing: 8) {
            reasonChip(
                "回数",
                value: Self.countText(focus.count - focus.previousCount),
                difference: focus.count - focus.previousCount
            )

            reasonChip(
                "1 回あたり",
                value: Self.signed(focus.unitPrice - focus.previousUnitPrice),
                difference: focus.unitPrice - focus.previousUnitPrice
            )
        }
    }

    static func countText(_ difference: Int) -> String {
        if difference > 0 {
            return "+\(difference) 回"
        }

        return difference < 0 ? "−\(-difference) 回" : "±0 回"
    }
}

private extension ReviewAnalysisView {
    func reasonChip(
        _ title: String,
        value: String,
        difference: Int
    ) -> some View {
        let isUp = difference > 0
        let color = isUp ? Palette.increase : Palette.subtext

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            Text(value)
                .displayFont(.body, weight: .bold)
                .foregroundStyle(color)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(isUp ? 0.1 : 0.06), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(.soft))
        }
    }
}
