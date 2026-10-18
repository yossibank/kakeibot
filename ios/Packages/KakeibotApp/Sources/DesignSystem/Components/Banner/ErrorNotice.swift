public struct ErrorNotice: Equatable, Sendable {
    public private(set) var message: String?
    public private(set) var count = 0

    public init() {}
}

public extension ErrorNotice {
    mutating func show(_ message: String) {
        self.message = message
        count += 1
    }

    mutating func clear() {
        message = nil
    }
}
