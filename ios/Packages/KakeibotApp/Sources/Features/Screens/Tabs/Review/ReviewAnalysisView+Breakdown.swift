import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    func waterfall(_ focus: ReviewBreakdown.Focus) -> some View {
        let steps = steps(of: focus)
        let top = steps.map { max($0.start, $0.end) }.max() ?? 1

        return panel {
            VStack(alignment: .leading, spacing: 12) {
                panelTitle("前の\(unit)から\(currentName)まで")

                HStack(alignment: .top, spacing: 12) {
                    ForEach(steps, id: \.self) { step in
                        Button {
                            onOpen(step.kind == .previous ? .previous : .current)
                        } label: {
                            VStack(spacing: 8) {
                                column(step, top: max(top, 1))
                                    .frame(height: Self.chartHeight + 32)

                                Text(step.title)
                                    .textFont(.caption2)
                                    .foregroundStyle(Self.titleColor(step))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(PressButtonStyle())
                    }
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.accent.opacity(.muted))
                        .frame(height: 1)
                        .offset(y: Self.chartHeight + 32)
                }
            }
        }
    }

    func memo(_ rows: [ReviewBreakdown.Row]) -> some View {
        let gains = rows.map(Self.gain)
        let total = gains.compactMap(\.self).filter { $0 > 0 }.reduce(0, +)
        let largest = rows.map(\.amount).max() ?? 1
        let showsGain = total > 0
        let title = showsGain ? "増えた分はどこから" : "同じメモの記録"

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
    enum StepKind {
        case previous
        case change
        case current
    }

    struct Step: Hashable {
        let title: String
        let start: Int
        let end: Int
        let text: String
        let kind: StepKind
    }

    static let chartHeight: CGFloat = 140

    func column(
        _ step: Step,
        top: Int
    ) -> some View {
        let low = CGFloat(min(step.start, step.end))
        let high = CGFloat(max(step.start, step.end))
        let scale = Self.chartHeight / CGFloat(top)
        let color = Self.stepColor(step)
        let glow = step.kind == .previous ? 0 : 0.2

        return VStack(spacing: 4) {
            Spacer(minLength: 0)

            Text(step.text)
                .sansFont(.caption, weight: .semibold)
                .foregroundStyle(Self.labelColor(step))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(color.opacity(.subtle), in: Capsule())
                .monospacedDigit()

            RoundedRectangle(cornerRadius: 4)
                .fill(Self.stepFill(step))
                .frame(height: max((high - low) * scale, 3))
                .shadow(color: color.opacity(glow), radius: 4)
                .scaleEffect(y: hasAppeared ? 1 : 0.02, anchor: .bottom)

            Color.clear
                .frame(height: low * scale)
        }
        .frame(maxWidth: .infinity)
    }

    func memoRow(
        _ row: ReviewBreakdown.Row,
        gain: Int?,
        ratio: Double,
        isFirst: Bool
    ) -> some View {
        let isUp = (gain ?? 0) > 0
        let amount = gain.map(Self.signed) ?? ReviewInsight.yen(row.amount)
        let count = row.previousCount > 0
            ? "\(row.previousCount) → \(row.count) 回"
            : "\(row.count) 回"
        let color = isUp ? Palette.increase : Palette.accent
        let isFilled = isUp || gain == nil

        return Button {
            onOpen(.memo(row.name))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
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

    static func labelColor(_ step: Step) -> Color {
        switch step.kind {
        case .previous: Palette.text
        case .change: step.end > step.start ? Palette.increase : Palette.subtext
        case .current: Palette.accentStrong
        }
    }

    static func stepColor(_ step: Step) -> Color {
        switch step.kind {
        case .previous: Palette.accent.opacity(.muted)
        case .change: step.end > step.start ? Palette.increase : Palette.subtext.opacity(.medium)
        case .current: Palette.accent
        }
    }

    static func stepFill(_ step: Step) -> AnyShapeStyle {
        switch step.kind {
        case .previous: AnyShapeStyle(Palette.accent.opacity(.muted).gradient)
        case .change: AnyShapeStyle(stepColor(step).gradient)
        case .current: AnyShapeStyle(Palette.gold)
        }
    }

    static func titleColor(_ step: Step) -> Color {
        let isUp = step.kind == .change && step.end > step.start
        return isUp ? Palette.increase : Palette.subtext
    }

    func steps(of focus: ReviewBreakdown.Focus) -> [Step] {
        let previous = focus.previousAmount
        let counted = previous + focus.countEffect

        return [
            Step(
                title: "前の\(unit)",
                start: 0,
                end: previous,
                text: ReviewInsight.yen(previous),
                kind: .previous
            ),
            Step(
                title: "回数の分",
                start: previous,
                end: counted,
                text: Self.signed(focus.countEffect),
                kind: .change
            ),
            Step(
                title: "金額の分",
                start: counted,
                end: focus.amount,
                text: Self.signed(focus.priceEffect),
                kind: .change
            ),
            Step(
                title: currentName,
                start: 0,
                end: focus.amount,
                text: ReviewInsight.yen(focus.amount),
                kind: .current
            )
        ]
    }
}
