import DesignSystem
import SwiftUI

struct SettingsPagedGrid<Item: Identifiable, Tile: View>: View {
    @State private var page: Int?
    @State private var width: CGFloat = 0

    let items: [Item]
    let selected: Item.ID?
    let columns: Int
    let rows: Int
    let spacing: CGFloat
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        let pages = Self.pages(of: items, size: columns * rows)

        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(pages.indices, id: \.self) { index in
                        SettingsTileGrid(
                            items: pages[index],
                            columns: columns,
                            spacing: spacing,
                            tile: tile
                        )
                        .frame(width: width)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollPosition(id: $page)
            .clipped()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                self.width = width
            }

            if pages.count > 1 {
                PageDots(count: pages.count, current: page ?? 0)
            }
        }
        .onAppear {
            page = pages.firstIndex { page in
                page.contains { $0.id == selected }
            } ?? 0
        }
    }
}

private extension SettingsPagedGrid {
    static func pages(
        of items: [Item],
        size: Int
    ) -> [[Item]] {
        stride(from: 0, to: items.count, by: size).map { start in
            Array(items[start..<min(start + size, items.count)])
        }
    }
}
