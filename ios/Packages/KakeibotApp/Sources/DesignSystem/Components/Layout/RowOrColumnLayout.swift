import SwiftUI

public struct RowOrColumnLayout: Layout {
    let rowSpacing: CGFloat
    let columnSpacing: CGFloat

    public init(
        rowSpacing: CGFloat,
        columnSpacing: CGFloat
    ) {
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
    }
}

public extension RowOrColumnLayout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map {
            $0.sizeThatFits(.unspecified)
        }

        let rowWidth = rowWidth(of: sizes)

        guard rowWidth > proposal.width ?? .infinity else {
            let rowHeight = sizes.map(\.height).max() ?? 0
            return CGSize(width: rowWidth, height: rowHeight)
        }

        let columnWidth = sizes.map(\.width).max() ?? 0
        let columnHeight = columnHeight(of: sizes)

        return CGSize(width: columnWidth, height: columnHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviews.map {
            $0.sizeThatFits(.unspecified)
        }

        let isRow = rowWidth(of: sizes) <= bounds.width
        var x = bounds.minX
        var y = bounds.minY

        for (subview, size) in zip(subviews, sizes) {
            let point = isRow
                ? CGPoint(x: x, y: bounds.midY)
                : CGPoint(x: bounds.minX, y: y + size.height / 2)

            subview.place(
                at: point,
                anchor: .leading,
                proposal: ProposedViewSize(size)
            )

            x += size.width + rowSpacing
            y += size.height + columnSpacing
        }
    }
}

private extension RowOrColumnLayout {
    func rowWidth(of sizes: [CGSize]) -> CGFloat {
        let gaps = rowSpacing * CGFloat(max(sizes.count - 1, 0))
        return sizes.map(\.width).reduce(0, +) + gaps
    }

    func columnHeight(of sizes: [CGSize]) -> CGFloat {
        let gaps = columnSpacing * CGFloat(max(sizes.count - 1, 0))
        return sizes.map(\.height).reduce(0, +) + gaps
    }
}
