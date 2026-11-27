public extension ReviewModel {
    struct PeriodCursor: Equatable, Sendable {
        public private(set) var offset = 0
        public private(set) var isMovingForward = true

        public init() {}
    }
}

public extension ReviewModel.PeriodCursor {
    var isCurrent: Bool {
        offset == 0
    }

    func canMove(by count: Int) -> Bool {
        offset + count <= 0
    }

    mutating func move(by count: Int) {
        guard canMove(by: count) else {
            return
        }

        isMovingForward = count > 0
        offset += count
    }

    mutating func moveToCurrent() {
        isMovingForward = true
        offset = 0
    }

    mutating func restart(movingForward isMovingForward: Bool) {
        self.isMovingForward = isMovingForward
        offset = 0
    }
}
