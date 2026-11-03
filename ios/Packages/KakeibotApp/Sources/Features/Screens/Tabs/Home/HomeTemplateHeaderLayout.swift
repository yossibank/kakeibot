import SwiftUI

struct HomeTemplateHeaderLayout: Layout {
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
        let sideHeight = max(sizes[0].height, sizes[2].height)

        guard Self.fitsInRow(sizes, width: width, spacing: spacing) else {
            let stackedHeight = sideHeight + spacing + sizes[1].height

            return CGSize(width: width, height: stackedHeight)
        }

        let rowHeight = max(sideHeight, sizes[1].height)

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
        let sideHeight = isRow ? bounds.height : max(sizes[0].height, sizes[2].height)
        let sideY = bounds.minY + sideHeight / 2
        let centerY = isRow ? bounds.midY : bounds.maxY - sizes[1].height / 2
        let leading = CGPoint(x: bounds.minX, y: sideY)
        let center = CGPoint(x: bounds.midX, y: centerY)
        let trailing = CGPoint(x: bounds.maxX, y: sideY)

        subviews[0].place(
            at: leading,
            anchor: .leading,
            proposal: ProposedViewSize(sizes[0])
        )

        subviews[1].place(
            at: center,
            anchor: .center,
            proposal: ProposedViewSize(sizes[1])
        )

        subviews[2].place(
            at: trailing,
            anchor: .trailing,
            proposal: ProposedViewSize(sizes[2])
        )
    }
}

private extension HomeTemplateHeaderLayout {
    static func rowWidth(
        of sizes: [CGSize],
        spacing: CGFloat
    ) -> CGFloat {
        let side = max(sizes[0].width, sizes[2].width)

        return side * 2 + sizes[1].width + spacing * 2
    }

    static func fitsInRow(
        _ sizes: [CGSize],
        width: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        rowWidth(of: sizes, spacing: spacing) <= width
    }
}
