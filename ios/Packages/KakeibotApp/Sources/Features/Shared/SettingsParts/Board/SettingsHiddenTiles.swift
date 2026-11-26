import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsHiddenTiles<Item: Identifiable, Face: View>: View {
    let fold: SettingsFold
    let title: String
    let items: [Item]
    let drag: SettingsDrag<Item.ID>
    let grid: SettingsBoardGrid
    let space: String
    let layout: SettingsBoardLayout
    let face: (Item) -> Face
    let onTap: (Item) -> Void
    let onFollow: (Item.ID, CGPoint) -> Void
    let onDrop: () -> Void
    let onDeleteAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: layout == .tiles ? 8 : 12) {
            SettingsHiddenTitle(
                fold: fold,
                title: title,
                count: items.count,
                onDeleteAll: onDeleteAll
            )

            if !fold.isClosed {
                if layout == .tiles {
                    LazyVGrid(columns: columns, spacing: grid.spacing) {
                        ForEach(items) { item in
                            tile(item)
                        }
                    }
                } else {
                    ForEach(items) { item in
                        tile(item)
                    }
                }
            }
        }
    }
}

extension SettingsHiddenTiles {
    init<Model: SettingsBoardModel>(
        fold: SettingsFold,
        title: String,
        grid: SettingsBoardGrid,
        controller: SettingsBoardController<Model>,
        space: String,
        layout: SettingsBoardLayout,
        @ViewBuilder face: @escaping (Item) -> Face,
        onTap: @escaping (Item) -> Void,
        onDeleteAll: @escaping () -> Void
    ) where Model.Item == Item {
        self.init(
            fold: fold,
            title: title,
            items: controller.model.output.hidden,
            drag: controller.drag,
            grid: grid,
            space: space,
            layout: layout,
            face: face,
            onTap: onTap,
            onFollow: { id, location in
                controller.followHidden(id, to: location)
            },
            onDrop: {
                controller.dropHidden()
            },
            onDeleteAll: onDeleteAll
        )
    }
}

private extension SettingsHiddenTiles {
    func tile(_ item: Item) -> some View {
        let lifted = drag.hiddenOffset(of: item.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let opacity: Double = isLifted ? 0 : layout == .tiles ? 1 : 0.5
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

private extension SettingsHiddenTiles {
    var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: grid.spacing),
            count: grid.columns
        )
    }
}
