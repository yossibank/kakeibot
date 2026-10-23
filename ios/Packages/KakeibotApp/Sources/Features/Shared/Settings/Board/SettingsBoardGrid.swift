import CoreGraphics

struct SettingsBoardGrid {
    var width: CGFloat = 0

    let columns: Int
    let itemHeight: CGFloat
    let spacing: CGFloat
}

extension SettingsBoardGrid {
    var itemWidth: CGFloat {
        let gaps = spacing * CGFloat(columns - 1)

        return max((width - gaps) / CGFloat(columns), 0)
    }

    func height(slots: Int) -> CGFloat {
        let rows = (slots + columns - 1) / columns
        let gaps = spacing * CGFloat(max(rows - 1, 0))

        return itemHeight * CGFloat(rows) + gaps
    }

    func center(at index: Int) -> CGPoint {
        let column = index % columns
        let row = index / columns
        let x = (itemWidth + spacing) * CGFloat(column) + itemWidth / 2
        let y = (itemHeight + spacing) * CGFloat(row) + itemHeight / 2

        return CGPoint(x: x, y: y)
    }

    func index(
        at point: CGPoint,
        count: Int
    ) -> Int {
        let width = itemWidth + spacing
        let height = itemHeight + spacing
        let column = min(max(Int(point.x / width), 0), columns - 1)
        let row = max(Int(point.y / height), 0)

        return min(row * columns + column, count - 1)
    }
}
