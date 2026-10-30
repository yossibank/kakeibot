import Core
import DesignSystem
import Store
import SwiftUI

extension TemplateListView {
    func follow(
        _ template: EntryTemplate,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: template) ?? 0
        let start = grid.center(at: index)

        let center = drag.follow(template.id, from: start, to: location) { next in
            follow(template, to: next)
        }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(template.id, to: target)
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
        _ id: EntryTemplate.ID,
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

    func hide(_ id: EntryTemplate.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func requestDelete(_ id: EntryTemplate.ID) {
        deleting = id
        isConfirmingDelete = true
    }

    func delete(_ id: EntryTemplate.ID) {
        Task {
            deletion = await model.delete(id)
        }
    }

    func deleteHidden() {
        Task {
            deletion = await model.deleteHidden().deletion
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }

    func show(_ id: EntryTemplate.ID) {
        Task {
            await model.show(id)
        }
    }
}
