import CloudKit
import Core
@testable import Store
@testable import Sync
import Testing

struct SyncRouteSendTests {
    @Test(arguments: [CKError.Code.unknownItem, .zoneNotFound])
    func finishesDeletionOfRecordThatCloudNoLongerHas(code: CKError.Code) {
        let change = Self.change(saveZone: nil, deleteZones: [SyncZone.own])
        let own = Self.id(in: SyncZone.own)
        let sent = Self.sent(failedDeletes: [SyncRoute.Failure(id: own, code: code)])

        let result = Self.route.settle(sent, sending: [Self.key: change])

        #expect(result.finished == [change])
        #expect(result.deleted == [own])
        #expect(result.failed.isEmpty)
        #expect(result.problem == nil)
        #expect(result.updatesProblem)
    }

    @Test
    func keepsDeletionThatCloudRefused() {
        let change = Self.change(saveZone: nil, deleteZones: [SyncZone.own])
        let own = Self.id(in: SyncZone.own)
        let sent = Self.sent(failedDeletes: [SyncRoute.Failure(id: own, code: .networkFailure)])

        let result = Self.route.settle(sent, sending: [Self.key: change])

        #expect(result.finished.isEmpty)
        #expect(result.deleted.isEmpty)
        #expect(result.failed == [Self.key])
        #expect(result.problem == .networkUnavailable)
        #expect(result.updatesProblem)
    }

    @Test
    func keepsFailedSaveOutOfNextQueueWithoutTouchingProblem() {
        let change = Self.change(saveZone: SyncZone.own, deleteZones: [])
        let own = Self.id(in: SyncZone.own)
        let sent = Self.sent(failedSaves: [SyncRoute.Failure(id: own, code: .serverRecordChanged)])

        let result = Self.route.settle(sent, sending: [Self.key: change])

        #expect(result.finished.isEmpty)
        #expect(result.failed == [Self.key])
        #expect(result.problem == nil)
        #expect(result.updatesProblem == false)
    }

    @Test
    func clearsProblemWhenSomethingIsSent() {
        let change = Self.change(saveZone: SyncZone.own, deleteZones: [])
        let sent = Self.sent(saved: [Self.id(in: SyncZone.own)])

        let result = Self.route.settle(sent, sending: [Self.key: change])

        #expect(result.finished == [change])
        #expect(result.failed.isEmpty)
        #expect(result.problem == nil)
        #expect(result.updatesProblem)
    }

    @Test
    func namesFirstProblemAmongFailuresOfSavesAndDeletions() {
        let own = Self.id(in: SyncZone.own)
        let wallet = Self.id(in: Self.ownWallet)

        let sent = Self.sent(
            failedSaves: [
                SyncRoute.Failure(id: own, code: .serverRecordChanged),
                SyncRoute.Failure(id: wallet, code: .quotaExceeded)
            ],
            failedDeletes: [SyncRoute.Failure(id: own, code: .networkFailure)]
        )

        let result = Self.route.settle(sent, sending: [:])

        #expect(result.problem == .quotaExceeded)
        #expect(result.updatesProblem)
    }

    @Test
    func leavesProblemToOwnDatabaseWhenSharedOneFails() {
        let shared = SyncRoute(isShared: true, isSyncEnabled: true, knowsZones: true, owners: [:])
        let own = Self.id(in: SyncZone.own)

        let sent = Self.sent(
            saved: [Self.id(in: Self.ownWallet)],
            failedSaves: [SyncRoute.Failure(id: own, code: .quotaExceeded)]
        )

        let result = shared.settle(sent, sending: [:])

        #expect(result.problem == .quotaExceeded)
        #expect(result.updatesProblem == false)
    }

    @Test
    func finishesMovedSaveWhoseOldRecordIsAlreadyGone() {
        let change = Self.change(saveZone: Self.ownWallet, deleteZones: [SyncZone.own])
        let own = Self.id(in: SyncZone.own)

        let sent = Self.sent(
            saved: [Self.id(in: Self.ownWallet)],
            failedDeletes: [SyncRoute.Failure(id: own, code: .unknownItem)]
        )

        let result = Self.route.settle(sent, sending: [Self.key: change])

        #expect(result.finished == [change])
        #expect(result.staleDeletions == [own])
        #expect(result.deleted == [own])
        #expect(result.failed.isEmpty)
    }

    @Test
    func countsFailureOfUnreadableRecordOnlyForProblem() {
        let sent = Self.sent(
            failedSaves: [SyncRoute.Failure(id: nil, code: .quotaExceeded)],
            failedDeletes: [SyncRoute.Failure(id: nil, code: .unknownItem)]
        )

        let result = Self.route.settle(sent, sending: [:])

        #expect(result.deleted.isEmpty)
        #expect(result.failed.isEmpty)
        #expect(result.problem == .quotaExceeded)
        #expect(result.updatesProblem)
    }

    @Test
    func changesNothingWhenNothingIsSent() {
        let change = Self.change(saveZone: SyncZone.own, deleteZones: [])

        let result = Self.route.settle(Self.sent(), sending: [Self.key: change])

        #expect(result == SyncRoute.Settle(
            finished: [],
            staleDeletions: [],
            deleted: [],
            failed: [],
            problem: nil,
            updatesProblem: false
        ))
    }
}

private extension SyncRouteSendTests {
    static let key = SyncKey(table: .entry, id: "e")
    static let ownWallet = SyncZone.wallet(.init())
    static let route = SyncRoute(
        isShared: false,
        isSyncEnabled: true,
        knowsZones: true,
        owners: [:]
    )

    static func id(in zoneName: String) -> SyncRecordID {
        SyncRecordID(key: key, zoneName: zoneName)
    }

    static func sent(
        saved: [SyncRecordID] = [],
        deleted: [SyncRecordID] = [],
        failedSaves: [SyncRoute.Failure] = [],
        failedDeletes: [SyncRoute.Failure] = []
    ) -> SyncRoute.Sent {
        SyncRoute.Sent(
            saved: saved,
            deleted: deleted,
            failedSaves: failedSaves,
            failedDeletes: failedDeletes
        )
    }

    static func change(
        saveZone: String?,
        deleteZones: [String]
    ) -> SyncChange {
        SyncChange(
            key: key,
            isDeletion: saveZone == nil,
            saveZone: saveZone,
            deleteZones: deleteZones,
            version: 1
        )
    }
}
