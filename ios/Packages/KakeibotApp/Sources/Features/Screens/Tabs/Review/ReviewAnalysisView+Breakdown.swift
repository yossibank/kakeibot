import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    func focus(_ focus: ReviewBreakdown.Focus) -> some View {
        let isCountUp = focus.hasPrevious && focus.count > focus.previousCount
        let isPriceChanged = focus.hasPrevious && !focus.hasSamePrice
        let isPriceUp = isPriceChanged && focus.unitPrice > focus.previousUnitPrice

        return VStack(alignment: .leading, spacing: 16) {
            sectionTitle("01", "\(focus.name)の動き")

            HStack(spacing: 8) {
                metric(
                    "回数",
                    value: "\(focus.count) 回",
                    change: countChange(of: focus),
                    isUp: isCountUp
                )

                metric(
                    "1 回の額",
                    value: ReviewInsight.yen(focus.unitPrice),
                    change: priceChange(of: focus),
                    isUp: isPriceUp
                )
            }
            .fixedSize(horizontal: false, vertical: true)

            if focus.hasPrevious,
               focus.amount > focus.previousAmount {
                waterfall(focus)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func memo(_ rows: [ReviewBreakdown.Row]) -> some View {
        let cells = rows.map { max($0.count, $0.previousCount) }.max() ?? 0
        let showsCells = cells <= Self.maximumCells
        let hasPrevious = rows.contains { $0.previousCount > 0 }

        return VStack(alignment: .leading, spacing: 16) {
            sectionTitle("02", "同じメモの記録")

            ForEach(rows, id: \.name) { row in
                memoRow(
                    row,
                    cells: showsCells ? cells : 0,
                    hasPrevious: hasPrevious
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private extension ReviewAnalysisView {
    enum CellKind {
        case kept
        case added
        case removed
        case empty
    }

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

    static let maximumCells = 24

    @ViewBuilder
    func cell(_ kind: CellKind) -> some View {
        switch kind {
        case .kept:
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.accent.opacity(.muted).gradient)

        case .added:
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.increase.gradient)
                .shadow(color: Palette.increase.opacity(.muted), radius: 3, y: 2)

        case .removed:
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Palette.subtext.opacity(.medium), style: .dashed)

        case .empty:
            Color.clear
        }
    }

    func memoRow(
        _ row: ReviewBreakdown.Row,
        cells: Int,
        hasPrevious: Bool
    ) -> some View {
        let color = Self.changeColor(from: row.previousCount, to: row.count)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(Self.countText(of: row, hasPrevious: hasPrevious))
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(color)
                    .fixedSize()

                Text(ReviewInsight.yen(row.amount))
                    .displayFont(.small, weight: .semibold)
                    .foregroundStyle(Palette.text)
                    .fixedSize()
                    .frame(minWidth: 72, alignment: .trailing)
            }
            .monospacedDigit()

            if cells > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<cells, id: \.self) { index in
                        cell(Self.cellKind(at: index, of: row))
                            .frame(maxWidth: .infinity)
                            .frame(height: 10)
                    }
                }
            }
        }
    }

    func metric(
        _ title: String,
        value: String,
        change: String?,
        isUp: Bool
    ) -> some View {
        let color = isUp ? Palette.increase : Palette.subtext
        let top = isUp ? Palette.increase.opacity(.subtle) : Palette.accent.opacity(.faint)
        let edge = isUp ? Palette.increase.opacity(.soft) : Palette.accent.opacity(.subtle)

        let fill = LinearGradient(
            colors: [top, top.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )

        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(value)
                .displayFont(.title, weight: .bold)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let change {
                Text(change)
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(.subtle), in: Capsule())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(fill, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(edge)
        }
    }

    func stepBar(
        _ step: Step,
        scale: Int
    ) -> some View {
        let low = min(step.start, step.end)
        let high = max(step.start, step.end)
        let color = Self.stepColor(step)

        return GeometryReader { proxy in
            let width = proxy.size.width
            let left = width * CGFloat(low) / CGFloat(max(scale, 1))
            let length = max(width * CGFloat(high - low) / CGFloat(max(scale, 1)), 2)

            Capsule()
                .fill(color.gradient)
                .frame(width: length)
                .shadow(color: color.opacity(.soft), radius: 3, y: 2)
                .offset(x: left)
        }
        .frame(height: 14)
    }

    func waterfall(_ focus: ReviewBreakdown.Focus) -> some View {
        let steps = steps(of: focus)
        let scale = steps.map { max($0.start, $0.end) }.max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(steps, id: \.self) { step in
                HStack(spacing: 8) {
                    Text(step.title)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 84, alignment: .leading)

                    stepBar(step, scale: scale)

                    Text(step.text)
                        .displayFont(.small, weight: .semibold)
                        .foregroundStyle(Self.stepTextColor(step))
                        .fixedSize()
                        .frame(minWidth: 76, alignment: .trailing)
                }
                .monospacedDigit()
            }
        }
        .padding(16)
        .background(Palette.faint, in: .rect(cornerRadius: 16))
    }
}

private extension ReviewAnalysisView {
    static func cellKind(
        at index: Int,
        of row: ReviewBreakdown.Row
    ) -> CellKind {
        let kept = min(row.count, row.previousCount)

        if index < kept {
            return .kept
        }

        if index < row.count {
            return .added
        }

        return index < row.previousCount ? .removed : .empty
    }

    static func changeColor(
        from previous: Int,
        to current: Int
    ) -> Color {
        current > previous && previous > 0
            ? Palette.increase
            : Palette.subtext
    }

    static func countText(
        of row: ReviewBreakdown.Row,
        hasPrevious: Bool
    ) -> String {
        guard hasPrevious else {
            return "\(row.count) 回"
        }

        let mark = if row.count > row.previousCount {
            " ▲"
        } else if row.count < row.previousCount {
            " ▼"
        } else {
            ""
        }

        return "\(row.previousCount) → \(row.count) 回\(mark)"
    }

    static func signed(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(ReviewInsight.yen(amount))"
        }

        return amount < 0 ? "−\(ReviewInsight.yen(-amount))" : "±0円"
    }

    static func stepColor(_ step: Step) -> Color {
        switch step.kind {
        case .previous: Palette.accent.opacity(.muted)
        case .change: step.end > step.start ? Palette.increase : Palette.subtext.opacity(.medium)
        case .current: Palette.accent
        }
    }

    static func stepTextColor(_ step: Step) -> Color {
        guard step.kind == .change else {
            return Palette.text
        }

        return step.end > step.start ? Palette.increase : Palette.subtext
    }

    func countChange(of focus: ReviewBreakdown.Focus) -> String? {
        guard focus.hasPrevious else {
            return nil
        }

        let diff = focus.count - focus.previousCount

        if diff == 0 {
            return "± 前の\(unit)と同じ"
        }

        let mark = diff > 0 ? "▲" : "▼"
        return "\(mark) \(abs(diff)) 回（\(focus.previousCount) 回）"
    }

    func priceChange(of focus: ReviewBreakdown.Focus) -> String? {
        guard focus.hasPrevious else {
            return nil
        }

        guard !focus.hasSamePrice else {
            return "± 前の\(unit)と同じ"
        }

        let diff = focus.unitPrice - focus.previousUnitPrice
        let mark = diff > 0 ? "▲" : "▼"

        return "\(mark) \(ReviewInsight.yen(abs(diff)))"
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
                title: "1 回の額の分",
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
