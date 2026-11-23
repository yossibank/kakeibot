public struct SyncActivity: Hashable, Sendable {
    public let isSyncEnabled: Bool
    public let isSharing: Bool

    public init(
        isSyncEnabled: Bool,
        isSharing: Bool
    ) {
        self.isSyncEnabled = isSyncEnabled
        self.isSharing = isSharing
    }
}

public extension SyncActivity {
    var isActive: Bool {
        isSyncEnabled || isSharing
    }
}
