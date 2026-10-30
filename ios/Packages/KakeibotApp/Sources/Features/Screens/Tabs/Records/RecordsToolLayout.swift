import SwiftUI

struct RecordsToolLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map {
            $0.sizeThatFits(.unspecified)
        }

        let width = proposal.width ?? Self.rowWidth(of: sizes, spacing: spacing)

        guard Self.fitsInRow(sizes, width: width, spacing: spacing) else {
            let stackedHeight = sizes[0].height + spacing + sizes[1].height

            return CGSize(width: width, height: stackedHeight)
        }

        let rowHeight = max(sizes[0].height, sizes[1].height)

        return CGSize(width: width, height: rowHeight)
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

        let isRow = Self.fitsInRow(sizes, width: bounds.width, spacing: spacing)
        let leadingY = isRow ? bounds.midY : bounds.minY + sizes[0].height / 2
        let trailingY = isRow ? bounds.midY : bounds.maxY - sizes[1].height / 2
        let leading = CGPoint(x: bounds.minX, y: leadingY)
        let trailing = CGPoint(x: bounds.maxX, y: trailingY)

        subviews[0].place(
            at: leading,
            anchor: .leading,
            proposal: ProposedViewSize(sizes[0])
        )

        subviews[1].place(
            at: trailing,
            anchor: .trailing,
            proposal: ProposedViewSize(sizes[1])
        )
    }
}

private extension RecordsToolLayout {
    static func rowWidth(
        of sizes: [CGSize],
        spacing: CGFloat
    ) -> CGFloat {
        sizes[0].width + spacing + sizes[1].width
    }

    static func fitsInRow(
        _ sizes: [CGSize],
        width: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        rowWidth(of: sizes, spacing: spacing) <= width
    }
}
