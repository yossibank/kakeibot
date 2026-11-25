import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsTileBoard<Item: Identifiable, Face: View>: View {
    @Binding var width: CGFloat

    let grid: SettingsBoardGrid
    let items: [Item]
    let drag: SettingsDrag<Item.ID>
    let space: String
    let face: (Item) -> Face
    let onTap: ((Item) -> Void)?
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
            self.width = width
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
            .modifier(SettingsTapAction(action: onTap.map { tap in { tap(item) } }))
            .gesture(
                LiftGesture(in: space) { location in
                    onFollow(item.id, location)
                } onEnd: {
                    onDrop()
                }
            )
    }
}

extension SettingsTileBoard {
    init<Model: SettingsBoardModel>(
        grid: SettingsBoardGrid,
        width: Binding<CGFloat>,
        controller: SettingsBoardController<Model>,
        space: String,
        @ViewBuilder face: @escaping (Item) -> Face,
        onTap: ((Item) -> Void)? = nil
    ) where Model.Item == Item {
        self.init(
            width: width,
            grid: grid,
            items: controller.model.output.shown,
            drag: controller.drag,
            space: space,
            face: face,
            onTap: onTap,
            onFollow: { id, location in
                controller.follow(id, to: location)
            },
            onDrop: {
                controller.drop()
            }
        )
    }
}

private struct SettingsTapAction: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}
