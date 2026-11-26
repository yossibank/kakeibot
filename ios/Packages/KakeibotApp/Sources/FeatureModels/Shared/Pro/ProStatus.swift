public enum ProStatus: Sendable, Equatable {
    case locked
    case unlocked
    case revoked
}

public extension ProStatus {
    var isUnlocked: Bool {
        self == .unlocked
    }
}
