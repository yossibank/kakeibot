import CloudKit
import Store
@testable import Sync
import Testing

struct SyncSendProblemTests {
    @Test(
        arguments: [
            (CKError.Code.quotaExceeded, SyncSendProblem.quotaExceeded),
            (.networkUnavailable, .networkUnavailable),
            (.networkFailure, .networkUnavailable),
            (.notAuthenticated, .notAllowed),
            (.permissionFailure, .notAllowed)
        ]
    )
    func namesProblemThatStopsSending(
        code: CKError.Code,
        expected: SyncSendProblem
    ) {
        #expect(SyncSendProblem(code) == expected)
    }

    @Test(arguments: [CKError.Code.serverRecordChanged, .zoneNotFound, .unknownItem])
    func leavesRetriedFailuresUnnamed(code: CKError.Code) {
        #expect(SyncSendProblem(code) == nil)
    }
}
