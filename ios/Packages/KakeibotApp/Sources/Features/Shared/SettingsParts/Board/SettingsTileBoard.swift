import DesignSystem
import SwiftUI

struct SettingsTileBoard<Item: Identifiable, Face: View>: View {
    @Binding var grid: SettingsBoardGrid

    let items: [Item]
    let drag: SettingsDrag<Item.ID>
    let space: String
    let face: (Item) -> Face
    let onTap: (Item) -> Void
    let onFollow: (Item.ID, CGPoint) -> Void
    let onDrop: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                tile(item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: grid.height(slots: items.count))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            grid.width = width
        }
    }
}

private extension SettingsTileBoard {
    func tile(_ item: Item) -> some View {
        let isLifted = drag.isLifted(item.id)
        let index = items.firstIndex { $0.id == item.id } ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return face(item)
            .frame(width: grid.itemWidth, height: grid.itemHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                onTap(item)
            }
            .gesture(
                LiftGesture(in: space) { location in
                    onFollow(item.id, location)
                } onEnd: {
                    onDrop()
                }
            )
    }
}
