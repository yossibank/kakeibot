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
        openStamp = nil
    }

    func takePendingDay() -> LocalDate? {
        guard let pendingDay else {
            return nil
        }

        self.pendingDay = nil

        return pendingDay
    }

    func closeShelf() {
        if shelf != HomeModel.Shelf() {
            shelf = HomeModel.Shelf()
        }
    }
}
