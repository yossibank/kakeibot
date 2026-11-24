public enum ProStatus: Sendable, Equatable {
    case locked
    case unlocked
    case revoked

    public var isUnlocked: Bool {
        self == .unlocked
    }
}
