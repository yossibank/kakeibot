public extension EntryVoiceFlow {
    struct Rounds: Equatable, Sendable {
        public private(set) var starts = 0
        public private(set) var ends = 0

        public init() {}
    }
}

public extension EntryVoiceFlow.Rounds {
    mutating func start() {
        starts += 1
    }

    mutating func end() {
        ends += 1
    }
}
