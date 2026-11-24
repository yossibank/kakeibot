import Core
import FeatureModels
import Store
import SwiftUI

@MainActor
struct SettingsBoardController<Model: SettingsBoardModel> {
    let model: Model
    let drag: SettingsDrag<Model.Item.ID>
    let grid: SettingsBoardGrid
    let hiddenId: Binding<Model.Item.ID?>
    let deletion: Binding<Deletion?>
    let bulkDelete: Binding<SettingsBulkDelete?>

    init(
        model: Model,
        drag: SettingsDrag<Model.Item.ID>,
        grid: SettingsBoardGrid,
        hiddenId: Binding<Model.Item.ID?>,
        deletion: Binding<Deletion?>,
        bulkDelete: Binding<SettingsBulkDelete?> = .constant(nil)
    ) {
        self.model = model
        self.drag = drag
        self.grid = grid
        self.hiddenId = hiddenId
        self.deletion = deletion
        self.bulkDelete = bulkDelete
    }
}

extension SettingsBoardController {
    func follow(
        _ id: Model.Item.ID,
        to location: CGPoint
    ) {
        let index = model.output.shown.firstIndex { $0.id == id } ?? 0
        let start = grid.center(at: index)

        let center = drag.follow(id, from: start, to: location) { next in
            follow(id, to: next)
        }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.output.shown.count)

        withAnimation(.snappy) {
            model.move(id, to: target)
        }
    }

    func drop() {
        drop { id in
            hide(id)
        }
    }

    func drop(onHide: (Model.Item.ID) -> Void) {
        switch drag.drop() {
        case let .hide(id):
            onHide(id)

        case .move:
            Task {
                await model.finishMoving()
            }

        case nil:
            break
        }
    }

    func followHidden(
        _ id: Model.Item.ID,
        to location: CGPoint
    ) {
        drag.followHidden(id, to: location)
    }

    func dropHidden() {
        guard let id = drag.dropHidden() else {
            return
        }

        show(id)
    }

    func hide(_ id: Model.Item.ID) {
        Task {
            if await model.hide(id) {
                hiddenId.wrappedValue = id
            }
        }
    }

    func show(_ id: Model.Item.ID) {
        Task {
            await model.show(id)
        }
    }

    func delete(_ id: Model.Item.ID) {
        Task {
            deletion.wrappedValue = await model.delete(id)
        }
    }

    func deleteHidden() {
        Task {
            let result = await model.deleteHidden()

            bulkDelete.wrappedValue = result
            deletion.wrappedValue = result.deletion
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }
}
