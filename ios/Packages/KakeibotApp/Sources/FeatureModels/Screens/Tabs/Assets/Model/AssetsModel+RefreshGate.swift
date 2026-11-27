public extension AssetsModel {
    struct RefreshGate: Equatable, Sendable {
        public private(set) var isRunning = false
        public private(set) var isRequested = false

        public init() {}
    }
}

public extension AssetsModel.RefreshGate {
    mutating func request() -> Bool {
        isRequested = true

        guard !isRunning else {
            return false
        }

        isRunning = true

        return true
    }

    mutating func next() -> Bool {
        guard isRequested else {
            isRunning = false
            return false
        }

        isRequested = false

        return true
    }
}
