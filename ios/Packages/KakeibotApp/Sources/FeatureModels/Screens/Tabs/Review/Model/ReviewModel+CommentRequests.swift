public extension ReviewModel {
    struct CommentRequests: Equatable, Sendable {
        public private(set) var keys: Set<String> = []

        public init() {}
    }
}

public extension ReviewModel.CommentRequests {
    mutating func begin(_ key: String) -> Bool {
        keys.insert(key).inserted
    }

    mutating func cancel(_ key: String) {
        keys.remove(key)
    }
}
