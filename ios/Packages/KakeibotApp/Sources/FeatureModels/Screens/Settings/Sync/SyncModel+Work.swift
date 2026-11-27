import Core

public extension SyncModel {
    enum Work: Hashable, Sendable {
        case switching
        case sharing(Wallet.ID)
    }
}

public extension SyncModel.Work {
    var isSharing: Bool {
        if case .sharing = self {
            return true
        }

        return false
    }
}
