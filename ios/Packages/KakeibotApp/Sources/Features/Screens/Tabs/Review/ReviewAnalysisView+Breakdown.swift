import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    func memo(_ rows: [ReviewBreakdown.Row]) -> some View {
        let gains = rows.map(Self.gain)
        let total = gains.compactMap(\.self).filter { $0 > 0 }.reduce(0, +)
        let largest = rows.map(\.amount).max() ?? 1
        let showsGain = total > 0
        let title = showsGain ? "どこで増えた" : "同じメモの記録"

        return panel {
            VStack(alignment: .leading, spacing: 4) {
                panelTitle(title)

                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    let gain = gains[index] ?? 0

                    let ratio = showsGain
                        ? Double(max(gain, 0)) / Double(total)
                        : Double(row.amount) / Double(max(largest, 1))

                    memoRow(
                        row,
                        gain: showsGain ? gain : nil,
                        ratio: ratio,
                        isFirst: index == 0
                    )
                }
            }
        }
    }
}

private extension ReviewAnalysisView {
    func memoRow(
        _ row: ReviewBreakdown.Row,
        gain: Int?,
        ratio: Double,
        isFirst: Bool
    ) -> some View {
        let isUp = (gain ?? 0) > 0
        let color = isUp ? Palette.increase : Palette.accent

        return Button {
            onOpen(.memo(row.name))
        } label: {
            HStack(spacing: 12) {
                Text(row.name.prefix(1))
                    .displayFont(.small, weight: .bold)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(.subtle), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(color.opacity(.muted))
                    }

                memoDetail(row, gain: gain, ratio: ratio)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if !isFirst {
                Rectangle()
                    .fill(Palette.accent.opacity(.subtle))
                    .frame(height: 1)
            }
        }
    }

    func memoDetail(
        _ row: ReviewBreakdown.Row,
        gain: Int?,
        ratio: Double
    ) -> some View {
        let isUp = (gain ?? 0) > 0
        let amount = gain.map(Self.signed) ?? ReviewInsight.yen(row.amount)
        let count = row.previousCount > 0
            ? "\(row.previousCount) → \(row.count) 回"
            : "\(row.count) 回"
        let color = isUp ? Palette.increase : Palette.accent
        let isFilled = isUp || gain == nil

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.name)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(count)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize()

                Spacer(minLength: 4)

                Text(amount)
                    .displayFont(.small, weight: .semibold)
                    .foregroundStyle(isUp ? Palette.increase : Palette.text)
                    .fixedSize()

                if gain != nil {
                    Text("\(Int((ratio * 100).rounded()))%")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .fixedSize()
                        .frame(minWidth: 32, alignment: .trailing)
                }

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.subtext.opacity(.medium))
            }
            .monospacedDigit()

            Capsule()
                .fill(Palette.accent.opacity(.faint))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(color.gradient)
                            .opacity(isFilled ? 1 : 0)
                            .frame(width: proxy.size.width * ratio * (hasAppeared ? 1 : 0))
                    }
                }
        }
    }
}

private extension ReviewAnalysisView {
    static func gain(of row: ReviewBreakdown.Row) -> Int? {
        guard
            row.previousCount > 0,
            let previous = row.previousAmount
        else {
            return nil
        }

        return row.amount - previous
    }
}
