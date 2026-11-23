public enum SyncStopReason: String, Sendable {
    case signedOut = "signed_out"
    case accountChanged = "account_changed"
    case cloudReplaced = "cloud_replaced"
}
