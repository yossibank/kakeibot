import CloudKit
import Store
@testable import Sync
import Testing

struct SyncRouteTests {
    @Test
    func sendsOwnZoneOnlyWhileSyncIsOn() {
        let on = Self.route(isSyncEnabled: true)
        let off = Self.route(isSyncEnabled: false)

        #expect(on.sends(to: SyncZone.own))
        #expect(off.sends(to: SyncZone.own) == false)
        #expect(off.sends(to: Self.ownWallet))
    }

    @Test
    func leavesJoinedZonesToSharedEngine() {
        let own = Self.route(isSyncEnabled: true)
        let shared = Self.route(isShared: true, isSyncEnabled: true)

        #expect(own.sends(to: Self.joinedWallet) == false)
        #expect(shared.sends(to: Self.joinedWallet))
        #expect(shared.sends(to: Self.ownWallet) == false)
        #expect(shared.sends(to: SyncZone.own) == false)
    }

    @Test
    func receivesOwnZoneOnlyWhileSyncIsOn() {
        let on = Self.route(isSyncEnabled: true)
        let off = Self.route(isSyncEnabled: false)
        let shared = Self.route(isShared: true, isSyncEnabled: false)

        #expect(on.receives(from: SyncZone.own))
        #expect(off.receives(from: SyncZone.own) == false)
        #expect(off.receives(from: Self.ownWallet))
        #expect(shared.receives(from: Self.joinedWallet))
        #expect(shared.receives(from: SyncZone.own) == false)
    }

    @Test
    func finishesSaveAndDeletesItsOldZone() {
        let route = Self.route(isSyncEnabled: true)
        let change = Self.change(saveZone: Self.ownWallet, deleteZones: [SyncZone.own])
        let saved = SyncRecordID(key: change.key, zoneName: Self.ownWallet)
        let stale = SyncRecordID(key: change.key, zoneName: SyncZone.own)

        let result = route.finish(
            sending: [change.key: change],
            saved: [saved],
            deleted: []
        )

        #expect(result.finished == [change])
        #expect(result.staleDeletions == [stale])
    }

    @Test
    func keepsSaveToAnotherZoneSending() {
        let route = Self.route(isSyncEnabled: true)
        let change = Self.change(saveZone: Self.ownWallet, deleteZones: [])
        let saved = SyncRecordID(key: change.key, zoneName: SyncZone.own)

        let result = route.finish(
            sending: [change.key: change],
            saved: [saved],
            deleted: []
        )

        #expect(result.finished.isEmpty)
        #expect(result.staleDeletions.isEmpty)
    }

    @Test
    func keepsStaleDeletionOfOwnZoneWhileSyncIsOff() {
        let route = Self.route(isSyncEnabled: false)
        let change = Self.change(saveZone: Self.ownWallet, deleteZones: [SyncZone.own])
        let saved = SyncRecordID(key: change.key, zoneName: Self.ownWallet)

        let result = route.finish(
            sending: [change.key: change],
            saved: [saved],
            deleted: []
        )

        #expect(result.finished == [change])
        #expect(result.staleDeletions.isEmpty)
    }

    @Test
    func finishesDeletionOnlyWhenEverySentZoneIsDeleted() {
        let route = Self.route(isSyncEnabled: true)
        let change = Self.change(saveZone: nil, deleteZones: [SyncZone.own, Self.ownWallet])
        let own = SyncRecordID(key: change.key, zoneName: SyncZone.own)
        let wallet = SyncRecordID(key: change.key, zoneName: Self.ownWallet)

        let partly = route.finish(
            sending: [change.key: change],
            saved: [],
            deleted: [own]
        )

        let fully = route.finish(
            sending: [change.key: change],
            saved: [],
            deleted: [own, wallet]
        )

        #expect(partly.finished.isEmpty)
        #expect(fully.finished == [change])
    }

    @Test
    func finishesDeletionWithoutZonesItDoesNotSend() {
        let route = Self.route(isSyncEnabled: false)
        let change = Self.change(saveZone: nil, deleteZones: [SyncZone.own, Self.ownWallet])
        let wallet = SyncRecordID(key: change.key, zoneName: Self.ownWallet)

        let result = route.finish(
            sending: [change.key: change],
            saved: [],
            deleted: [wallet]
        )

        #expect(result.finished == [change])
    }

    @Test
    func ignoresChangesThatAreNotSending() {
        let route = Self.route(isSyncEnabled: true)
        let key = SyncKey(table: .wallet, id: "w")
        let saved = SyncRecordID(key: key, zoneName: SyncZone.own)

        let result = route.finish(
            sending: [:],
            saved: [saved],
            deleted: [saved]
        )

        #expect(result.finished.isEmpty)
    }

    @Test(
        arguments: [
            (CKError.Code.serverRecordChanged, false, SyncRoute.Retry.resolveConflict),
            (.zoneNotFound, false, .saveZoneAgain),
            (.zoneNotFound, true, .skip),
            (.unknownItem, false, .sendAgain),
            (.unknownItem, true, .sendAgain),
            (.quotaExceeded, false, .skip),
            (.networkUnavailable, true, .skip)
        ]
    )
    func choosesRetryByFailure(
        code: CKError.Code,
        isShared: Bool,
        expected: SyncRoute.Retry
    ) {
        let route = Self.route(isShared: isShared, isSyncEnabled: true)

        #expect(route.retry(after: code) == expected)
    }
}

private extension SyncRouteTests {
    static let ownWallet = SyncZone.wallet(.init())
    static let joinedWallet = SyncZone.wallet(.init())

    static func route(
        isShared: Bool = false,
        isSyncEnabled: Bool
    ) -> SyncRoute {
        SyncRoute(
            isShared: isShared,
            isSyncEnabled: isSyncEnabled,
            owners: [joinedWallet: "_owner"]
        )
    }

    static func change(
        saveZone: String?,
        deleteZones: [String]
    ) -> SyncChange {
        SyncChange(
            key: SyncKey(table: .entry, id: "e"),
            isDeletion: saveZone == nil,
            saveZone: saveZone,
            deleteZones: deleteZones,
            version: 1
        )
    }
}
