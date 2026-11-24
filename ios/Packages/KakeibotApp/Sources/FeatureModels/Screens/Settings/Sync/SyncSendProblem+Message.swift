import Store

public extension SyncSendProblem {
    var message: String {
        switch self {
        case .quotaExceeded: "iCloud の容量が足りず、送れていません"
        case .networkUnavailable: "ネットにつながらず、送れていません"
        case .notAllowed: "iCloud に送る権限が無く、送れていません"
        }
    }
}
