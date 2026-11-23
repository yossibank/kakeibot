import Core
import DesignSystem
import Store
import SwiftUI

extension RecurringListView {
    var controller: SettingsBoardController<RecurringListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: Self.grid,
            hiddenId: $hiddenId,
            deletion: $deletion
        )
    }

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

    func requestDelete(_ id: Recurring.ID) {
        deleting = id
        isConfirmingDelete = true
    }
}
