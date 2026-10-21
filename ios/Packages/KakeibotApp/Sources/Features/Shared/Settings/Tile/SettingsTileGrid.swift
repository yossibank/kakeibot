import DesignSystem
import SwiftUI

struct SettingsTileGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        let rows = Self.rows(of: items, size: columns)

        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    ForEach(rows[index]) { item in
                        tile(item)
                    }

                    ForEach(rows[index].count..<columns, id: \.self) { _ in
                        Color.clear
                            .gridCellUnsizedAxes(.vertical)
                    }
                }
            }
        }
    }
}

private extension SettingsTileGrid {
    static func rows(
        of items: [Item],
        size: Int
    ) -> [[Item]] {
        stride(from: 0, to: items.count, by: size).map { start in
            Array(items[start..<min(start + size, items.count)])
        }
    }
}
