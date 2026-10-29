import Core
import Store
import SwiftUI

extension CategoryListView {
    func follow(
        _ category: EntryCategory,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: category) ?? 0
        let start = grid.center(at: index)

        let center = drag.follow(category.id, from: start, to: location) { next in
            follow(category, to: next)
        }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(category.id, to: target)
        }
    }

    func drop() {
        switch drag.drop() {
        case let .hide(id):
            hide(id)
        case .move:
            Task {
                await model.finishMoving()
            }
        case nil:
            break
        }
    }

    func followHidden(
        _ id: EntryCategory.ID,
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

    func deleteHidden() {
        Task {
            deletion = await model.deleteHidden()
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }

    func show(_ id: EntryCategory.ID) {
        Task {
            await model.show(id)
        }
    }
}

private extension CategoryListView {
    func hide(_ id: EntryCategory.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }
}
