import CloudKit
import Store

extension SyncSendProblem {
    init?(_ code: CKError.Code) {
        switch code {
        case .quotaExceeded:
            self = .quotaExceeded
        case .networkUnavailable, .networkFailure:
            self = .networkUnavailable
        case .notAuthenticated, .permissionFailure:
            self = .notAllowed
        default:
            return nil
        }
    }
}
