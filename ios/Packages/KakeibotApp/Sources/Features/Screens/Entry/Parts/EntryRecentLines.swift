import SwiftUI

struct EntryRecentLines: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let lines = arrange(subviews).filter { !$0.indices.isEmpty }
        let width = lines.map(\.width).max() ?? 0
        let heights = lines.map(\.height).reduce(0, +)
        let gaps = CGFloat(max(lines.count - 1, 0)) * Self.spacing
        return CGSize(width: width, height: heights + gaps)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var y = bounds.minY

        for line in arrange(subviews) where !line.indices.isEmpty {
            var x = bounds.minX

            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + Self.spacing
            }

            y += line.height + Self.spacing
        }
    }
}

private extension EntryRecentLines {
    struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    static var spacing: CGFloat {
        8
    }

    func arrange(_ subviews: Subviews) -> [Line] {
        var lines = [Line(), Line()]

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let target = lines[0].width <= lines[1].width ? 0 : 1
            let gap = lines[target].indices.isEmpty ? 0 : Self.spacing

            lines[target].indices.append(index)

            lines[target].width += gap + size.width
            lines[target].height = max(lines[target].height, size.height)
        }

        return lines
    }
}
