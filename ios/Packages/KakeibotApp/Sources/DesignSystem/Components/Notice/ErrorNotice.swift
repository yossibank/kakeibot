public struct ErrorNotice: Equatable, Sendable {
    public private(set) var message: String?
    public private(set) var tone: NoticeBanner.Tone = .error
    public private(set) var count = 0

    public init() {}
}

public extension ErrorNotice {
    mutating func show(_ message: String) {
        self.message = message
        tone = .error
        count += 1
    }

    mutating func inform(_ message: String) {
        self.message = message
        tone = .info
        count += 1
    }

    mutating func clear() {
        message = nil
    }
}
