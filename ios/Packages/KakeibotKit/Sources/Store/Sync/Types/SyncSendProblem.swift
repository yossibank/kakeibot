public enum SyncSendProblem: String, Sendable {
    case quotaExceeded = "quota_exceeded"
    case networkUnavailable = "network_unavailable"
    case notAllowed = "not_allowed"
}
