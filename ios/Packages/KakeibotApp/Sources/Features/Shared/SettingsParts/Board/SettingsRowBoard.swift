import DesignSystem
import SwiftUI

struct SettingsRowBoard<Item: Identifiable, Face: View>: View {
    let items: [Item]
    let drag: SettingsDrag<Item.ID>
    let grid: SettingsBoardGrid
    let space: String
    let face: (Item) -> Face
    let onFollow: (Item.ID, CGPoint) -> Void
    let onDrop: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(items) { item in
                row(item)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: grid.height(slots: items.count), alignment: .top)
    }
}

private extension SettingsRowBoard {
    func row(_ item: Item) -> some View {
        let isLifted = drag.isLifted(item.id)
        let index = items.firstIndex { $0.id == item.id } ?? 0
        let center = isLifted ? drag.liftedCenter : grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return face(item)
            .frame(height: grid.itemHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .offset(y: center.y - grid.itemHeight / 2)
            .settingsLiftFrame(drag, \.rowFrames, id: item.id, in: space)
            .zIndex(layer)
            .gesture(
                LiftGesture(in: space) { location in
                    onFollow(item.id, location)
                } onEnd: {
                    onDrop()
                }
            )
    }
}
