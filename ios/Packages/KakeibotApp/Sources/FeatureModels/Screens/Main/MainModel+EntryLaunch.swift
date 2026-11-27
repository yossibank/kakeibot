public extension MainModel {
    struct EntryLaunch: Equatable, Sendable {
        public private(set) var startsReceipt = false
        public private(set) var isWarming = true

        public init() {}
    }
}

public extension MainModel.EntryLaunch {
    mutating func startReceipt() {
        startsReceipt = true
    }

    mutating func clearReceipt() {
        startsReceipt = false
    }

    mutating func finishWarming() {
        isWarming = false
    }
}
