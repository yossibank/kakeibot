import Core

public extension HomeModel {
    struct PendingDay: Equatable, Sendable {
        public private(set) var date: LocalDate?

        public init() {}
    }
}

public extension HomeModel.PendingDay {
    mutating func pick(_ date: LocalDate) {
        self.date = date
    }

    mutating func take() -> LocalDate? {
        let date = date
        self.date = nil
        return date
    }
}
