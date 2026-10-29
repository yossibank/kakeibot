public struct SyncStatus: Hashable, Sendable {
    public let isEnabled: Bool
    public let stopReason: SyncStopReason?

    public init(
        isEnabled: Bool,
        stopReason: SyncStopReason?
    ) {
        self.isEnabled = isEnabled
        self.stopReason = stopReason
    }
}

public enum SyncStopReason: String, Sendable {
    case signedOut = "signed_out"
    case accountChanged = "account_changed"
    case cloudReplaced = "cloud_replaced"
}
