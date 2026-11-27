import Core

public extension HomeModel {
    struct Shelf: Equatable, Sendable {
        public var query = ""
        public var isEditing = false
    }
}

public extension HomeModel.State {
    func pickStampDay(_ date: LocalDate) {
        pendingDay = date
        presented.closeAll()
    }

    func takePendingDay() -> LocalDate? {
        guard let pendingDay else {
            return nil
        }

        self.pendingDay = nil

        return pendingDay
    }

    func closeShelf() {
        if fields.shelf != HomeModel.Shelf() {
            fields.shelf = HomeModel.Shelf()
        }
    }
}
