import CloudKit
import Observation

@MainActor
@Observable
public final class SyncShareInbox {
    public static let shared = SyncShareInbox()

    public private(set) var pending: [CKShare.Metadata] = []
}

public extension SyncShareInbox {
    func receive(_ metadata: CKShare.Metadata) {
        pending.append(metadata)
    }

    func take() -> [CKShare.Metadata] {
        let taken = pending
        pending = []
        return taken
    }
}
