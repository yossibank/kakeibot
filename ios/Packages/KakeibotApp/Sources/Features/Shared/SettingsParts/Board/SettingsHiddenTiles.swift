import DesignSystem
import SwiftUI

struct SettingsHiddenTiles<Item: Identifiable, Face: View>: View {
    let flag: SettingsScreenFlag
    let title: String
    let items: [Item]
    let drag: SettingsDrag<Item.ID>
    let grid: SettingsBoardGrid
    let space: String
    let face: (Item) -> Face
    let onTap: (Item) -> Void
    let onFollow: (Item.ID, CGPoint) -> Void
    let onDrop: () -> Void
    let onDeleteAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsHiddenTitle(
                flag: flag,
                title: title,
                count: items.count,
                onDeleteAll: onDeleteAll
            )

            if flag.isOn {
                LazyVGrid(columns: columns, spacing: grid.spacing) {
                    ForEach(items) { item in
                        tile(item)
                    }
                }
            }
        }
    }
}

private extension SettingsHiddenTiles {
    var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: grid.spacing),
            count: grid.columns
        )
    }

    func tile(_ item: Item) -> some View {
        let lifted = drag.hiddenOffset(of: item.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return face(item)
            .frame(height: grid.itemHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .offset(offset)
            .settingsLiftFrame(
                drag,
                \.hiddenFrames,
                id: item.id,
                in: space
            )
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
