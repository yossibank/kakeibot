public struct ForegroundReturn: Sendable {
    private var wasBackground = false

    public init() {}
}

public extension ForegroundReturn {
    enum Phase: Sendable {
        case active
        case inactive
        case background
    }
}

public extension ForegroundReturn {
    mutating func receive(_ phase: Phase) -> Bool {
        switch phase {
        case .background:
            wasBackground = true
            return false

        case .active:
            defer {
                wasBackground = false
            }

            return wasBackground

        case .inactive:
            return false
        }
    }
}
