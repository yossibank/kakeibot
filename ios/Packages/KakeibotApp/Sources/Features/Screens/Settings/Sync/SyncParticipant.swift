public struct SyncParticipant: Hashable, Sendable {
    public let name: String
    public let state: State

    public init(
        name: String,
        state: State
    ) {
        self.name = name
        self.state = state
    }
}

public extension SyncParticipant {
    enum State: Sendable {
        case owner
        case joined
        case invited
    }
}
