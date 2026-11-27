import Foundation

public extension EntryVoiceFlow {
    struct Silence: Equatable, Sendable {
        public private(set) var startedAt: Date?

        public init() {}
    }
}

public extension EntryVoiceFlow.Silence {
    mutating func start(at date: Date) {
        startedAt = date
    }

    mutating func clear() {
        startedAt = nil
    }
}
