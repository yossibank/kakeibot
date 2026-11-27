import Core

public extension HomeModel {
    enum ShelfPage: Hashable, Sendable {
        case editing
    }
}

public extension HomeModel.State {
    func pickStampDay(_ date: LocalDate) {
        pendingDay.pick(date)
        presented.stamp.closeAll()
    }

    func takePendingDay() -> LocalDate? {
        guard pendingDay.date != nil else {
            return nil
        }

        return pendingDay.take()
    }

    func closeShelf() {
        if !fields.shelfQuery.isEmpty {
            fields.shelfQuery = ""
        }

        if presented.shelf.current != nil {
            presented.shelf.closeAll()
        }
    }

    func customize(_ item: SetupItem) {
        presented.customized = item
    }

    func finishCustomizing() {
        guard let customized = presented.customized else {
            return
        }

        presented.customized = nil
        presented.glow.show(customized)
    }
}
