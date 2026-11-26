import CloudKit
import Core
import Store

extension SyncRoute {
    struct Failure: Equatable {
        let id: SyncRecordID?
        let code: CKError.Code
    }

    struct Sent: Equatable {
        let saved: [SyncRecordID]
        let deleted: [SyncRecordID]
        let failedSaves: [Failure]
        let failedDeletes: [Failure]
    }

    struct Settle: Equatable {
        let finished: [SyncChange]
        let staleDeletions: [SyncRecordID]
        let deleted: [SyncRecordID]
        let failed: Set<SyncKey>
        let problem: SyncSendProblem?
        let updatesProblem: Bool
    }
}

extension SyncRoute {
    static let goneCodes: Set<CKError.Code> = [.unknownItem, .zoneNotFound]

    func settle(
        _ sent: Sent,
        sending: [SyncKey: SyncChange]
    ) -> Settle {
        let gone = sent.failedDeletes.filter { Self.goneCodes.contains($0.code) }
        let refused = sent.failedDeletes.filter { !Self.goneCodes.contains($0.code) }
        let deleted = sent.deleted + gone.compactMap(\.id)
        let failed = (sent.failedSaves + refused).compactMap(\.id?.key)
        let codes = (sent.failedSaves + sent.failedDeletes).map(\.code)
        let problem = codes.lazy.compactMap(SyncSendProblem.init).first
        let isSent = !sent.saved.isEmpty || !deleted.isEmpty

        let result = finish(
            sending: sending,
            saved: sent.saved,
            deleted: deleted
        )

        return Settle(
            finished: result.finished,
            staleDeletions: result.staleDeletions,
            deleted: deleted,
            failed: Set(failed),
            problem: problem,
            updatesProblem: !isShared && (problem != nil || isSent)
        )
    }
}

extension SyncRoute.Sent {
    init(
        _ sent: CKSyncEngine.Event.SentRecordZoneChanges,
        saved: [SyncRecordID]
    ) {
        self.init(
            saved: saved,
            deleted: sent.deletedRecordIDs.compactMap(SyncRecordID.init),
            failedSaves: sent.failedRecordSaves.map { failure in
                SyncRoute.Failure(
                    id: SyncRecordID(failure.record.recordID),
                    code: failure.error.code
                )
            },
            failedDeletes: sent.failedRecordDeletes.map { recordID, error in
                SyncRoute.Failure(id: SyncRecordID(recordID), code: error.code)
            }
        )
    }
}
