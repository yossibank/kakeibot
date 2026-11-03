import SwiftUI

public struct TwoColumnLayout: Layout {
    let spacing: CGFloat
    let minWidth: CGFloat

    public init(
        spacing: CGFloat,
        minWidth: CGFloat = 560
    ) {
        self.spacing = spacing
        self.minWidth = minWidth
    }
}

public extension TwoColumnLayout {
    enum Column: Sendable {
        case leading
        case trailing
    }
}

public extension TwoColumnLayout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? minWidth
        let frames = frames(of: subviews, width: width)
        let height = frames.map(\.maxY).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let frames = frames(of: subviews, width: bounds.width)

        for (subview, frame) in zip(subviews, frames) {
            let point = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)

            subview.place(
                at: point,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }
}

public extension View {
    func layoutColumn(_ column: TwoColumnLayout.Column) -> some View {
        layoutValue(key: TwoColumnKey.self, value: column)
    }
}

private extension TwoColumnLayout {
    func frames(
        of subviews: Subviews,
        width: CGFloat
    ) -> [CGRect] {
        let isWide = width >= minWidth
        let columnWidth = isWide ? (width - spacing) / 2 : width
        var leadingY: CGFloat = 0
        var trailingY: CGFloat = 0

        return subviews.map { subview in
            let column = isWide ? subview[TwoColumnKey.self] : .leading
            let proposal = ProposedViewSize(width: columnWidth, height: nil)
            let height = subview.sizeThatFits(proposal).height

            switch column {
            case .leading:
                let frame = CGRect(x: 0, y: leadingY, width: columnWidth, height: height)
                leadingY += height + spacing
                return frame

            case .trailing:
                let x = columnWidth + spacing
                let frame = CGRect(x: x, y: trailingY, width: columnWidth, height: height)
                trailingY += height + spacing
                return frame
            }
        }
    }
}

private struct TwoColumnKey: LayoutValueKey {
    static let defaultValue = TwoColumnLayout.Column.leading
}
