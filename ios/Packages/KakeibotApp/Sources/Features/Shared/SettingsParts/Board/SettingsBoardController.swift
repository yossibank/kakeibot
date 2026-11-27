import Core
import FeatureModels
import SwiftUI

@MainActor
struct SettingsBoardController<Model: SettingsBoardModel> {
    let model: Model
    let drag: SettingsDrag<Model.Item.ID>
    let grid: SettingsBoardGrid
}

extension SettingsBoardController {
    var removed: SettingsBoardRemoved<Model.Item.ID> {
        model.state.notices.removed
    }

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
            model.perform {
                await $0.finishMoving()
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
        model.perform {
            await $0.hide(id)
        }
    }

    func show(_ id: Model.Item.ID) {
        model.perform {
            await $0.show(id)
        }
    }

    func delete(_ id: Model.Item.ID) {
        model.perform {
            await $0.delete(id)
        }
    }

    func deleteHidden() {
        model.perform {
            await $0.deleteHidden()
        }
    }

    func restore(_ deletion: Deletion) {
        model.perform {
            await $0.restore(deletion)
        }
    }
}
