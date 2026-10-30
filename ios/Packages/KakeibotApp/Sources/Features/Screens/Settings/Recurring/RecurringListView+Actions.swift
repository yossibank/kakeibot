import Core
import DesignSystem
import Store
import SwiftUI

extension RecurringListView {
    func follow(
        _ row: RecurringListModel.Row,
        at index: Int,
        to location: CGPoint
    ) {
        let start = Self.grid.center(at: index)

        let center = drag.follow(row.id, from: start, to: location) { next in
            follow(row, at: index, to: next)
        }

        guard let center else {
            return
        }

        let target = Self.grid.index(at: center, count: model.rows.count)

        withAnimation(.snappy) {
            model.move(row.id, to: target)
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

    func hide(_ id: Recurring.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func requestDelete(_ id: Recurring.ID) {
        deleting = id
        isConfirmingDelete = true
    }

    func delete(_ id: Recurring.ID) {
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

    func show(_ id: Recurring.ID) {
        Task {
            await model.show(id)
        }
    }

    func followHidden(
        _ id: Recurring.ID,
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
}
