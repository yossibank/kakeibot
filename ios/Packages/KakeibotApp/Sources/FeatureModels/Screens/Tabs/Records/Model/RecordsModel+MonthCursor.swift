import Core

public extension RecordsModel {
    struct MonthCursor: Equatable, Sendable {
        public private(set) var month: YearMonth
        public private(set) var isMovingForward = true

        public init(month: YearMonth) {
            self.month = month
        }
    }
}

public extension RecordsModel.MonthCursor {
    mutating func move(by months: Int) {
        month = month.adding(months: months)
    }

    mutating func show(_ month: YearMonth) {
        self.month = month
    }

    mutating func head(forward isForward: Bool) {
        isMovingForward = isForward
    }
}
