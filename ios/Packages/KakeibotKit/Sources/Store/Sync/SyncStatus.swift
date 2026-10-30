import Foundation

public struct SyncStatus: Hashable, Sendable {
    public let isEnabled: Bool
    public let stopReason: SyncStopReason?
    public let sendProblem: SyncSendProblem?
    public let isFetching: Bool
    public let syncedAt: Date?

    public init(
        isEnabled: Bool,
        stopReason: SyncStopReason?,
        sendProblem: SyncSendProblem?,
        isFetching: Bool = false,
        syncedAt: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.stopReason = stopReason
        self.sendProblem = sendProblem
        self.isFetching = isFetching
        self.syncedAt = syncedAt
    }
}

public extension SyncStatus {
    static let off = Self(
        isEnabled: false,
        stopReason: nil,
        sendProblem: nil
    )
}

public enum SyncStopReason: String, Sendable {
    case signedOut = "signed_out"
    case accountChanged = "account_changed"
    case cloudReplaced = "cloud_replaced"
}

public enum SyncSendProblem: String, Sendable {
    case quotaExceeded = "quota_exceeded"
    case networkUnavailable = "network_unavailable"
    case notAllowed = "not_allowed"
}
