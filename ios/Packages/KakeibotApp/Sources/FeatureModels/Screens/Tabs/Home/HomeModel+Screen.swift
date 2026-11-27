import Core

public extension HomeModel {
    enum ShelfPage: Hashable, Sendable {
        case editing
    }
}

public extension HomeModel.State {
    func pickStampDay(_ date: LocalDate) {
        pendingDay = date
        presented.stamp.closeAll()
    }

    func takePendingDay() -> LocalDate? {
        guard let pendingDay else {
            return nil
        }

        self.pendingDay = nil

        return pendingDay
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
        customized = item
    }

    func finishCustomizing() {
        guard let customized else {
            return
        }

        self.customized = nil
        presented.glow.show(customized)
    }
}
